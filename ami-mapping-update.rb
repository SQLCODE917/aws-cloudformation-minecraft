#!/usr/bin/ruby

if __FILE__ == $0
    
    AWS_REGIONS = %w(eu-central-1 eu-north-1 eu-west-1 eu-west-2 eu-west-3 us-east-1).freeze
    IMAGE_PATTERN = "ubuntu/images/hvm-ssd/ubuntu-*-amd64-server-*".freeze

    images = {}
    snapshots = {}

    cli_query = "Images[*].[CreationDate,ImageId,BlockDeviceMappings[0].Ebs.SnapshotId,Description]".freeze
    cli_filters = "Name=name,Values=#{IMAGE_PATTERN} Name=description,Values=*LTS*".freeze
    cli_args = "--output text --owners 099720109477 --query \"#{cli_query}\" --filters #{cli_filters}".freeze

    args = 
    AWS_REGIONS.each do |region|
        image_info = %x(aws ec2 describe-images --region "#{region}" #{cli_args}).split("\n").sort.last.split("\t")
        images[region] = "amd64: \"#{image_info[1]}\" # #{image_info[3]}"
        snapshots[region] = "amd64: \"#{image_info[2]}\""
    end

    puts " " * 2 + "RegionToAMIID:"
    images.each do |region, image|
        puts " " * 4 + region + ":", " " * 6 + image
    end

    puts "", " " * 2 + "RegionToSnapshotID:"
    snapshots.each do |region, snapshot|
        puts " " * 4 + region + ":", " " * 6 + snapshot
    end
    
end