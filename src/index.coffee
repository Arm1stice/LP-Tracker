# Basic imports
e = require 'electron'
app = e.app
fs = require 'fs'
pathExists = require 'path-exists'
path = require 'path'
BrowserWindow = e.BrowserWindow
ipcMain = (require 'electron').ipcMain
loljs = require 'lol-js'
lolClient = null;
console.timeEnd 'init'

console.log "hehe xd"
