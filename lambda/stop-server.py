import boto3
import os

def handler(event, context):
    try:
        print('Server shutdown requested.')
        region = os.getenv('AWS_REGION')
        instance_id = os.getenv('INSTANCE_ID')
        ec2 = boto3.client('ec2', region_name=region)

        if not instance_id:
            raise RuntimeError('Could not resolve server instance ID.')

        statuses = ec2.describe_instance_status(InstanceIds=[instance_id])
        try:
            state = statuses['InstanceStatuses'][0]['InstanceState']['Name']
        except:
            state = None

        if 'running' == state:
            print('Initializing server shutdown.')
            ec2.stop_instances(InstanceIds=[instance_id])
        else:
            print('Server is not in running state, shutdown not initiated.')
            return { 'statusCode': 409, 'body': 'Conflicting State' }

        print('Request completed!')
    except Exception as exception:
        print('Failed to initiate server shutdown!')
        print(exception)
        return { 'statusCode': 500, 'body': 'Server Error' }

    return { 'statusCode': 200, 'body': 'Stopped' }