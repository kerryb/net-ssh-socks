# Net::SSH::Socks

## Description

Net::SSH::Socks is a library for programmatically creating a SOCKS proxy server that tunnels through SSH. Similar to Net::SSH::Service::Forward#local except the host is dynamic (determined by the client application, such as a browser).

## Synopsis

    require 'net/ssh/socks'

    Net::SSH.start('host', 'user') do |ssh|
      ssh.forward.socks(8080)
    end

Now, configure your browser to use a SOCKS proxy at localhost:8080

## Install

    gem install net-ssh-socks
