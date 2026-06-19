import boto3, os, botocore, json
from botocore.config import Config

# Writes report to S3 Bucket and sends Pre-signed URL to Security Admin and User
def reports_lambda(event, context):
    s3 = boto3.client('s3', config=Config(signature_version='s3v4'))
    sns = boto3.client('sns')

    # Access records from Lambda 3
    records = event if isinstance(event, list) else event.get('Payload', [event])
    
    # Access the scan_id from Lambda 3
    scan_id = records[0].get('scan_id') if records else None

    # Gets email from records from Lambda 3
    email = records[0].get('email') if records else None

    # Gets breach_names from records
    breach_names = [r.get('name') for r in records if r.get('name')]

    # Writes the complete report to be sent out and stored in S3 Bucket
    report = []
    report.append("## Breach Intelligence Report")
    report.append(f"**Scan ID:** `{scan_id}`")
    report.append(f"**Target Identifier:** `{records[0].get('email') if event else None} / {records[0].get('domain') if event else None}`")
    report.append(f"**Total Exposures Identified:** {len(records)}\n")
    report.append("### Executive Summary")
    report.append("This assessment details external credential and identity exposures identified for the target. Review the exposure points below to determine credential reuse risks and implement necessary mitigation controls.\n")
    report.append("### Exposure Details")
    for i in records:
        breach_name = i['name']
        try:
            pwn_count = f"{int(i['pwn_count']):,}"  
        except ValueError:
            pwn_count = 0
        data_classes = i['data_classes']
        date = i['breach_date']
        description = i['description']
        report.append(f"#### Source: {breach_name}")
        report.append(f"- **Exposure Date:** {date}")
        report.append(f"- **Impacted Accounts Count:** {pwn_count}")
        report.append(f"- **Compromised Data Attributes:** `{data_classes}`")
        report.append(f"- **Incident Summary:** {description}")
        report.append("\n---\n")
    final_report = "\n".join(report)

    # Stores Report
    response_4 = s3.put_object(
        Bucket=os.environ.get('S3_BUCKET_NAME'),
        Body=final_report.encode('utf-8'),
        Key=f"reports/{scan_id}.md"
        )
    

    

    # Generates pre-signed URL
    pre_signed_url = s3.generate_presigned_url('get_object', Params={'Bucket': os.environ.get('S3_BUCKET_NAME'), 'Key': f"reports/{scan_id}.md"}, ExpiresIn=3600)

    # Publish the Pre-signed URL to Security Admin and User and handle error case
    try:
        response_5 = sns.publish(
        TopicArn= os.environ.get('SNS_USER_ARN'),
        Message=f"Breach scan complete for {email}.\n\nTotal breaches found: {len(records)}\nBreaches identified: {', '.join(breach_names)}\n\nFull report: {pre_signed_url}",
        Subject="Breach Intelligence Report"
        )

        response_6 = sns.publish(
            TopicArn= os.environ.get('SNS_ADMIN_ARN'),
            Message=f"New breach report ready.\nScan ID: {scan_id}\nTarget: {email}\nBreaches found: {len(records)}\n\nAccess full report: {pre_signed_url}",
            Subject="Breach Intelligence Report"
            )
    except botocore.exceptions.ClientError as e:
        return {'statusCode': 500, 'body': json.dumps({'message': 'Failed to Send SNS Messages'})}
    
    # return status back to the User
    return {
        'status': 'complete',
        'scan_id': scan_id,
        'report_key': f"reports/{scan_id}.md"
    }