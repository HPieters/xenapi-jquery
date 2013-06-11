## XenAPI jQuery

A Xen API XMLRPC jQuery Client Library for working with XenServers & XCP.

### Usage

quick example how to use the library:

```
var client = new XenAPI(username,password,hostUrl);
client.init(function(error, result) {
    if(error) {

    } else {
        client.VM.get_all(function(error,result) {
            var all_vm = (result);
        })
    }
    var all_vm = result;
 })
```

Once you have done init any api call is possible, for a list of all the possibilties please visit the [api page](http://docs.vmd.citrix.com/XenServer/6.1.0/1.0/en_gb/api/index.html) of XenServer.


### 'Preprocessing'

- To turn the coffescript into javascript see http://coffeescript.org/.
- To minify the javascript see https://github.com/mishoo/UglifyJS/.

### Todo

- Reduce number of calls to server.
- Less callbacks
- Actualy implement a integrated test framework