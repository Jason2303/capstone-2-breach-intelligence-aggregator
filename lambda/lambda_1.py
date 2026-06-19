import boto3, botocore, json, os, uuid

# Lambda function triggers the Step Function
def trigger_lambda(event, context):
    stp = boto3.client('stepfunctions')
    # Gets the email and domain the user inputed and generates a random UUID
    try:
        body = json.loads(event.get('body') or '{}')
        email = body.get('email')
        domain = body.get('domain')
        scan_id = str(uuid.uuid4())
        
        if email is None and domain is None:
            return {'statusCode': 400, 'body': json.dumps({'message': 'Missing email or domain'})}
    
        # Starts the Step Function Execution
        response = stp.start_execution(
        stateMachineArn = os.environ.get('STATE_MACHINE_ARN'),
        name = scan_id,
        input = json.dumps({'email': email, 'domain': domain, 'scan_id': scan_id}),
        )

        
        
    # Catches error cases like Internal AWS service failure, Invalid JSON and TypeError
    except botocore.exceptions.ClientError as e:
        return {'statusCode': 500, 'body': json.dumps({'message': 'AWS service error'})}
    except json.JSONDecodeError:
        return {'statusCode': 400, 'body': json.dumps({'message': 'Invalid JSON'})}
    except TypeError:
        return {'statusCode': 400, 'body': json.dumps({'message': 'Missing body'})}
    

    
    # Returns 202 Accepted to the user confirming the scan has started
    return {
        'statusCode': 202,
        'body' : json.dumps({
            'scan_id': scan_id,
            'message': 'Scan started successfully'
        })
    }