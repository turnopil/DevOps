resource "aws_launch_configuration" "apache" {
  name = "apache-launch-configuration"
  image_id      = "ami-43a15f3e"
  instance_type = "${var.instance_type}"
  security_groups = ["${aws_security_group.apache.id}"]
  user_data       = <<EOF
#!/bin/bash
# ansible userdata (ami-43a15f3e)
set -x
cd /tmp
wget https://s3-eu-west-1.amazonaws.com/turnopil/mysql.sh
sudo chown ubuntu:ubuntu mysql.sh
sudo chmod 755 mysql.sh 
./mysql.sh

sudo apt-add-repository ppa:ansible/ansible -y 
sudo apt-get update
sudo apt-get install ansible -y
cd /tmp
wget https://s3-eu-west-1.amazonaws.com/turnopil/playbook1.tar.gz
sudo tar zxvf playbook1.tar.gz
cd /tmp/playbook
sudo ansible-playbook main.yml --connection=local -i localhost, -e target=localhost
EOF

  key_name        = "New"
}

resource "aws_autoscaling_group" "apachescale" {
  name = "apacge-asg"
  launch_configuration = "${aws_launch_configuration.apache.id}"
  availability_zones = ["${data.aws_availability_zones.apache.names}"]
  max_size = "${var.max_instance_asg}"
  min_size = 3
  desired_capacity = 3
  wait_for_elb_capacity = 3
  health_check_type = "ELB"
  load_balancers = ["${aws_elb.apachelb.id}"]
  vpc_zone_identifier = ["${data.aws_subnet.public_a.id}","${data.aws_subnet.public_b.id}","${data.aws_subnet.public_c.id}"]
  tag {
    key                 = "Name"
    value               = "apachetomcat"
    propagate_at_launch = "true"
  }
}

resource "aws_autoscaling_policy" "apache-memory-up" {
  adjustment_type = "ChangeInCapacity"
  autoscaling_group_name = "${aws_autoscaling_group.apachescale.id}"
  name = "apache-memory-up"
  scaling_adjustment = 1
  cooldown = 300
}

resource "aws_autoscaling_policy" "apache-cpu-up" {
  adjustment_type = "ChangeInCapacity"
  autoscaling_group_name = "${aws_autoscaling_group.apachescale.id}"
  name = "apache-cpu-up"
  scaling_adjustment = 1
  cooldown = 300
}

resource "aws_cloudwatch_metric_alarm" "memory-alarm-up" {
  alarm_name = "memory-alarm-up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = 2
  metric_name = "MemoryUtilization"
  namespace = "AWS/EC2"
  period = 120
  threshold = 80
  statistic = "Average"
  alarm_actions = ["${aws_autoscaling_policy.apache-memory-up.arn}"]
  dimensions {AutoScalingGroupName = "${aws_autoscaling_group.apachescale.id}"}

}

resource "aws_cloudwatch_metric_alarm" "cpu-alarm-up" {
  alarm_name = "cpu-alarm-up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = 2
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = 120
  threshold = 80
  statistic = "Average"
  alarm_actions = ["${aws_autoscaling_policy.apache-cpu-up.arn}"]
  dimensions {AutoScalingGroupName = "${aws_autoscaling_group.apachescale.id}"}

}

resource "aws_autoscaling_policy" "apache-memory-down" {
  adjustment_type = "ChangeInCapacity"
  autoscaling_group_name = "${aws_autoscaling_group.apachescale.id}"
  name = "apache-memory-down"
  scaling_adjustment = -1
  cooldown = 300
}

resource "aws_autoscaling_policy" "apache-cpu-down" {
  adjustment_type = "ChangeInCapacity"
  autoscaling_group_name = "${aws_autoscaling_group.apachescale.id}"
  name = "apache-cpu-down"
  scaling_adjustment = -1
  cooldown = 300
}

resource "aws_cloudwatch_metric_alarm" "memory-alarm-down" {
  alarm_name = "memory-alarm-down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = 2
  metric_name = "MemoryUtilization"
  namespace = "AWS/EC2"
  period = 120
  threshold = 20
  statistic = "Average"
  alarm_actions = ["${aws_autoscaling_policy.apache-memory-down.arn}"]
  dimensions {AutoScalingGroupName = "${aws_autoscaling_group.apachescale.id}"}
}

resource "aws_cloudwatch_metric_alarm" "cpu-alarm-down" {
  alarm_name = "cpu-alarm-down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = 2
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = 120
  threshold = 20
  statistic = "Average"
  alarm_actions = ["${aws_autoscaling_policy.apache-cpu-down.arn}"]
  dimensions {AutoScalingGroupName = "${aws_autoscaling_group.apachescale.id}"}

}
