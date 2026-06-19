import boto3, os, json

# Enrich email and domain data with necessary fields 
def data_enrichment(event, context):
    s3 = boto3.client('s3')

    # Gets email breaches records from Lambda 2
    email_breaches = event.get('Payload', event).get('email_breaches', [])

    # Gets domain breaches records from Lambda 2
    domain_breaches = event.get('Payload', event).get('domain_breaches', [])
    scan_id = event.get('Payload', event).get('scan_id')
    email = event.get('Payload', event).get('email')
    domain = event.get('Payload', event).get('domain')
    enriched_records = []

    # Loops through the breaches, maps the keys to the values. Adds the dictionary to a list
    for email_breach in email_breaches:
        enriched_record_email = {
        'name': email_breach.get('Name'),
        'title': email_breach.get('Title'),
        'domain': email_breach.get('Domain'),
        'breach_date': email_breach.get('BreachDate'),
        'added_date': email_breach.get('AddedDate'),
        'pwn_count': email_breach.get('PwnCount'),
        'description': email_breach.get('Description'),
        'data_classes': email_breach.get('DataClasses'),
        'is_verified': email_breach.get('IsVerified'),
        'is_sensitive': email_breach.get('IsSensitive'),
        'is_retired': email_breach.get('IsRetired'),
        'email': email,
        'scan_id': scan_id,
        }
        enriched_records.append(enriched_record_email)
        
    # Loops through the breaches, maps the keys to the values. Adds the dictionary to a list
    for domain_breach in domain_breaches:
        enriched_record_domain = {
        'name': domain_breach.get('Name'),
        'title': domain_breach.get('Title'),
        'domain': domain_breach.get('Domain'),
        'breach_date': domain_breach.get('BreachDate'),
        'added_date': domain_breach.get('AddedDate'),
        'pwn_count': domain_breach.get('PwnCount'),
        'description': domain_breach.get('Description'),
        'data_classes': domain_breach.get('DataClasses'),
        'is_verified': domain_breach.get('IsVerified'),
        'is_sensitive': domain_breach.get('IsSensitive'),
        'is_retired': domain_breach.get('IsRetired'),
        'domain': domain,
        'scan_id': scan_id,
        }
        enriched_records.append(enriched_record_domain)

    # Writes the enriched_records list to the Data Report Bucket
    response = s3.put_object(
        Bucket=os.environ.get('BUCKET'),
        Body=json.dumps(enriched_records).encode('utf-8'),
        Key=f"breach-data/{scan_id}.json"
        )
    
    # Returns breach data to Step Function to pass to Lambda 4
    return enriched_records