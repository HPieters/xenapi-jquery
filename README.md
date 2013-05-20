## XenAPI Javascript

A Xen API XMLRPC JavaScript Client Library for working with XenServers & XCP.

### Usage

A quick example how to use the library:

```javascript
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

For a more elaborate example see the test/ folder.

### 'Compile'

To turn the coffescript into javascript see http://coffeescript.org/
To minify the javascript see https://github.com/mishoo/UglifyJS/#install-npm