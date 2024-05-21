function getLambdaAPI() {
                       var xhttp = new XMLHttpRequest ();
                       xhttp.onreadystatechange = function() {
                       if (this.readyState = 4 && this.status == 200) {
                   document .getElementById ("my-demo") .innerHTML = this.responseText;
                                                                      }
                                                              };

                   xhttp.open("GET", "madheshwaranresumedeploy.s3-website-us-east-1.amazonaws.com",true);
                   xhttp.send();
                                                              }
 

