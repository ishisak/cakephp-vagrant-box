#!/bin/bash
vagrant ssh -c 'sudo systemctl restart php-fpm && sudo systemctl status php-fpm'
vagrant ssh -c 'sudo systemctl restart nginx && sudo systemctl status nginx'
