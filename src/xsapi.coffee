#
# jQuery XenServer API
# 
# Copyright (C) 2013 - Harrie Pieters
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published
# by the Free Software Foundation; version 2.1 only. 
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#

"use strict"

class window.xsapi

	#Public
	constructor : (username, password, hosturl) ->
		@username = username
		@password = password
		@hosturl = hosturl
		@session

	_connect = (username, password, hosturl, callback) ->
		fullHostURL		= 'http://'+hosturl+'/json'
		_xmlrpc(fullHostURL, "session.login_with_password", [username, password], callback)

	_serialize = (result, element) =>
		result[0][element]

	_responseHandler = (status, response, callback) =>
		if status is "success"
			messageStatus = _serialize(response,'Status')
			if messageStatus is "Success"
				ret = _serialize(response,'Value')
				callback(null,ret)
			else
				error = "Failed to authenticate."
				callback(error)	
		else
			error = "Failed to connect to specified host."
			callback(error)		

	_xmlrpc = (url, method, params = "[]",callback) ->
		
		$.xmlrpc
			url: url
			methodName: method
			params: params
			success: (response, status, jqXHR) ->
					_responseHandler(status, response, callback)
			error: (jqXHR, status, error) -> 
					_responseHandler(status, error, callback)


	#Private
	getSession : (callback) ->
		_connect(@username, @password, @hosturl, callback)
		
	getServerVersion : (callback) ->
		if @username? and @password? and @hosturl?
			if @session?
				callback(null,"ready to go")
			else
				callback(null,"Lets get a session first")
		else
			callback('No settings found, make sure you use init first.')

	