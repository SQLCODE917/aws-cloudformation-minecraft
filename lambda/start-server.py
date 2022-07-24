import boto3
import os

def handler(event, context):
    try:
        print('Server start up requested.')
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

        if 'stopped' == state or None is state:
            print('Starting server instance.')
            ec2.start_instances(InstanceIds=[instance_id])
        else:
            print('Server is currently not stopped, start up not initiated.')
            return { 'statusCode': 409, 'body': 'Conflicting State' }

        print('Request completed!')
    except Exception as exception:
        print('Failed to start up the server!')
        print(exception)
        return { 'statusCode': 500, 'body': 'Server Error' }

    return { 'statusCode': 200, 'body': 'Started' }