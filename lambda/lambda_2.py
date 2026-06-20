import boto3, botocore, os, urllib3, json

# Lambda function querying https://haveibeenpwned.com/
def HIBPQuery_lambda(event, context): 
    


    secrets = boto3.client('secretsmanager')
    
    # Get secret from Secret Manager
    try:
        response = secrets.get_secret_value(
            SecretId= os.environ.get('SECRETS_MANAGER_ARN')
        )
        secret = response['SecretString']
    except botocore.exceptions.ClientError as e:
        return {'statusCode': 500, 'body': json.dumps({'message': 'Failed to retrieve secret'})}

    # Get email and domain input
    email = event.get('email')
    domain = event.get('domain')


    # API call to https://haveibeenpwned.com/
    http = urllib3.PoolManager()
    url_email = f'https://haveibeenpwned.com/api/v3/breachedaccount/{email}'
    url_domain = f'https://haveibeenpwned.com/api/v3/breacheddomain/{domain}'
    email_breaches = []
    domain_breaches = []
    
    # Gets domain breaches from https://haveibeenpwned.com/ and handles error cases
    if domain:
        domain_response = http.request(
            'GET', 
            url_domain, 
            headers={
            'hibp-api-key': secret,
            'user-agent': 'BreachIntelligenceAggregator'
        })
        if domain_response.status == 200:
            domain_breaches = json.loads(domain_response.data.decode('utf-8'))
        elif domain_response.status == 404:
            domain_breaches = []
        elif domain_response.status == 429:
            return {'statusCode': 429, 'body': json.dumps({'message': 'HIBP rate limit exceeded'})}
        else:
            return {'statusCode': 500, 'body': json.dumps({'message': 'HIBP error'})}
    
 
    # Gets email breaches from https://haveibeenpwned.com/ and handles error cases
    if email:
        email_response = http.request(
            'GET', 
            url_email, 
            headers={
            'hibp-api-key': secret,
            'user-agent': 'BreachIntelligenceAggregator'
        })
        if email_response.status == 200:
            email_breaches = json.loads(email_response.data.decode('utf-8'))
        elif email_response.status == 404:
            email_breaches = []
        elif email_response.status == 429:
            return {'statusCode': 429, 'body': json.dumps({'message': 'HIBP rate limit exceeded'})}
        
        else:
            return {'statusCode': 500, 'body': json.dumps({'message': 'HIBP error'})}
    
    

    # Returns breach data to Step Function to pass to Lambda 3
    return {
        'email': email,
        'domain': domain,
        'scan_id': event.get('scan_id'),
        'email_breaches': email_breaches,
        'domain_breaches': domain_breaches
    }
   

    
    
        
    
    