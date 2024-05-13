function getLambdaAPI() {
                       var xhttp = new XMLHttpRequest ();
                       xhttp.onreadystatechange = function() {
                       if (this.readyState = 4 && this.status == 200) {
                   document .getElementById ("my-demo") .innerHTML = this.responseText;
                                                                      }
                                                              };

                   xhttp.open("GET", "https://5sdarfc50k.execute-api.us-east-1.amazonaws.com/Website_Visitors_Count",true);
                   xhttp.send();
                                                              }
 

