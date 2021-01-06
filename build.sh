#!/bin/bash

rm -rf node_modules
rm -rf public

npm install --force

hexo deploy
