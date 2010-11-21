# Net::SSH::Socks

## Description

Net::SSH::Socks is a library for programmatically creating a SOCKS proxy server that tunnels through SSH. Similar to Net::SSH::Service::Forward#local except the host is dynamic (determined by the client application, such as a browser).

Useful for securing traffic over SSH or getting in/out of a firewall.

## Use cases

* If your company blocks certain sites/resources but allows SSH, then you can tunnel out to a machine outside the firewall.
* If you need to access sites/resources inside a firewall, then you can tunnel into a machine inside the firewall.
* Encrypt your traffic to protect yourself from things like Firesheep on public wifi.

## Synopsis

    require 'net/ssh/socks'

    Net::SSH.start('host', 'user') do |ssh|
      ssh.forward.socks(8080)
      ssh.loop { true }
    end

Now, configure your browser to use a SOCKS proxy at localhost:8080

## Install

    gem install net-ssh-socks
