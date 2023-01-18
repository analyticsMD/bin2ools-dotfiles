#!/usr/bin/env python3

import json
import os

import boto3
import botocore.exceptions

def get_ec2_instances(session):
    # Get RDS Cluster Information from AWS
    instances = []
    ec2_client = session.client('ec2')
    try:
        instance_response = ec2_client.describe_instances()
        for res in instance_response['Reservations']:
            instances.extend(res['Instances'])
    except botocore.exceptions.ClientError as err:
        print(f"Couldn't get EC2 instance information. Here's why: {err.response['Error']['Code']}: {err.response['Error']['Message']}")
    except (botocore.exceptions.SSOTokenLoadError, botocore.exceptions.UnauthorizedSSOTokenError) as err:
        print(f"Couldn't get SSO Token for {[aws_profile_name]}.  Are you logged in? ({err})")
    return instances


def get_rds_clusters(session):
    # Get RDS Cluster Information from AWS
    clusters = {}
    rds_client = session.client('rds')
    try:
        cluster_response = rds_client.describe_db_clusters()
        clusters = cluster_response['DBClusters']
    except botocore.exceptions.ClientError as err:
        print(f"Couldn't get RDS cluster information. Here's why: {err.response['Error']['Code']}: {err.response['Error']['Message']}")
    except (botocore.exceptions.SSOTokenLoadError, botocore.exceptions.UnauthorizedSSOTokenError) as err:
        print(f"Couldn't get SSO Token for {[aws_profile_name]}.  Are you logged in? ({err})")
    return clusters

def truncate_endpoint(endpoint):
    # Truncate the endpoint - for old clusters that don't have a "stack" tag
    # We'll want to keep these ordered by length, decreasing, to avoid collisions.
    trunc = endpoint
    trunc = trunc.replace(".", "")
    trunc = trunc.replace("-for-nginx2", "")
    trunc = trunc.replace("-devops-r6g", "")
    trunc = trunc.replace("commonvpc", "")
    trunc = trunc.replace("-mirthdb2", "")
    trunc = trunc.replace("-mirthdb", "")
    trunc = trunc.replace("-restore", "")
    trunc = trunc.replace("-cluster", "")
    trunc = trunc.replace("-mirth2", "")
    trunc = trunc.replace("-mirth", "")
    trunc = trunc.replace("-test", "")
    trunc = trunc.replace("-amd", "")
    trunc = trunc.replace("-rds", "")
    trunc = trunc.replace("-bk", "")
    trunc = trunc.replace("-db", "")
    
    return trunc

def get_jump_host(instances, trunk):
    # This function is no longer used.  Kept here to preserve the logic, in case its ever needed again
    #print(f"Checking {trunk}...")
    name = ""
    id = ""
    for instance in instances:
        stack_tag = ""
        name_tag = ""
        #print(instance)
        #print(f"{instance['InstanceId']}, {instance['State']}")
        if instance['State']['Name'] == "running":
            for tag in instance['Tags']:
                if tag['Key'] == "Name":
                    name_tag = tag['Value']
                if tag['Key'] == 'qventus:stack' or tag['Key'] == 'Stack':
                    stack_tag = tag['Value']
            if ("vpn" not in name_tag and "cron" not in name_tag and 
                "cnc" not in name_tag and "ingestion" not in name_tag and 
                "qval" not in name_tag and "web" not in name_tag):
                if  stack_tag == trunk or trunk in name_tag:
                    #print(f"Found a match: {trunk}, {name_tag}, {stack_tag}")
                    # Don't overwrite <stack>-app-container instances, we prefer those
                    if "container" not in name:
                        name = name_tag
                        id = instance['InstanceId']
            if "emr" in trunk and name_tag == "common-vpn-pritunl":
                # Special case: emr cluster needs to use this jump host specifically
                name = name_tag
                id = instance['InstanceId']
                return name, id
    if name == "" and id == "":
        print(f"WARNING: Could not find a jump host for {trunk}.")
    return name, id


def save_rds_json(rds_json):
    HOME = os.getenv("HOME", "None")
    json_file = f"{HOME}/.bt/data/json/aws/rds.json"
    json_output = json.dumps(rds_json, sort_keys=True, indent=2)

    with open(json_file, "w") as outfile:
        outfile.write(json_output)


if __name__ == "__main__":
    aws_profile_name = 'prod-arch'
    session = boto3.Session(profile_name=aws_profile_name)
    clusters, instances, rds_json = {}, {}, {}
    rds_json["cluster"] = {}
    local_port = 3310
    clusters = get_rds_clusters(session)
    instances = get_ec2_instances(session)

    for cluster in clusters:
        if cluster['Status'] == "available":
            db_id = cluster['DBClusterIdentifier']
            rds_json["cluster"][db_id] = {}
            rds_json["cluster"][db_id]['endpoint'] = cluster['Endpoint'].replace("cluster-cum1rxsnisml.us-west-2.rds.amazonaws.com","")
            rds_json['cluster'][db_id]['trunk'] = ""
            rds_json["cluster"][db_id]['port'] = local_port
            local_port += 1
            for tag in cluster['TagList']:
                if tag['Key'] == 'qventus:stack' or tag['Key'] == 'Stack':
                    rds_json["cluster"][db_id]['trunk'] = tag['Value']
            if rds_json['cluster'][db_id]['trunk'] == "":
                # Cluster doesn't have a "stack" tag
                rds_json["cluster"][db_id]['trunk'] = truncate_endpoint(rds_json["cluster"][db_id]['endpoint'])
            #(rds_json["cluster"][db_id]['host'], rds_json["cluster"][db_id]['instance']) = \
            #    get_jump_host(instances, rds_json["cluster"][db_id]['trunk'])
            # No longer using get_jump_host.  Hard-coding jump host to the pritunl instance.
            rds_json["cluster"][db_id]['host'] = "common-vpn-pritunl"
            rds_json["cluster"][db_id]['instance'] = "i-08bccced8545e15b3"

            #print(f"{cluster['DBClusterIdentifier']}")
            #print(f"{cluster['Endpoint']}")

    save_rds_json(rds_json)
    #print(json.dumps(rds_json, sort_keys=True, indent=2))