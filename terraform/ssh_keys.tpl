#!/bin/bash
echo "template file is being used"
echo "${ansible_public_key}" >> /home/ubuntu/.ssh/authorized_keys