#!/usr/bin/ruby

if __FILE__ == $0
    
    AWS_REGIONS = %w(eu-central-1 eu-north-1 eu-west-1 eu-west-2 eu-west-3 us-east-1).freeze
    IMAGE_PATTERN = "ubuntu/images/hvm-ssd/ubuntu-jammy-*-amd64-server-*".freeze
    OPTIONS = 7.freeze

    images = {}
    snapshots = {}

    cli_query = "Images[*].[CreationDate,ImageId,BlockDeviceMappings[0].Ebs.SnapshotId,Description]".freeze
    cli_filters = "Name=name,Values=#{IMAGE_PATTERN} Name=description,Values=*LTS*".freeze
    cli_args = "--output text --owners 099720109477 --query \"#{cli_query}\" --filters #{cli_filters}".freeze

    AWS_REGIONS.each do |region|
        image_infos = %x(aws ec2 describe-images --region "#{region}" #{cli_args}).split("\n").sort.reverse
        images[region] = ""
        snapshots[region] = ""

        (0 ... OPTIONS).each do |index|
            image_info = image_infos[index].split("\t")
            images[region] += " " * 6 + "amd64: \"#{image_info[1]}\" # #{image_info[3]}\n"
            snapshots[region] += " " * 6 + "amd64: \"#{image_info[2]}\" # #{image_info[3]}\n"
        end
    end

    puts " " * 2 + "RegionToAMIID:"
    images.each do |region, image|
        puts " " * 4 + region + ":", image.chomp
    end

    puts "", " " * 2 + "RegionToSnapshotID:"
    snapshots.each do |region, snapshot|
        puts " " * 4 + region + ":", snapshot.chomp
    end
    
end
