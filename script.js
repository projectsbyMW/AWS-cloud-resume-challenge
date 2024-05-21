function getLambdaAPI() {
                       var xhttp = new XMLHttpRequest ();
                       xhttp.onreadystatechange = function() {
                       if (this.readyState = 4 && this.status == 200) {
                   document .getElementById ("my-demo") .innerHTML = this.responseText;
                                                                      }
                                                              };

                   xhttp.open("GET", "https://2g6twclm4h.execute-api.us-east-1.amazonaws.com/dev1",true);
                   xhttp.send();
                                                              }
 

