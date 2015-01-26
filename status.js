var head='<tr><th>Server</th><th>Status</th><th>Timestamp</th><th>Message</th></tr>';
var lastRun = 0;

$(document).ready(function(){
  console.log("Document ready");
  
  updateStatus();
  setInterval(function(){updateStatus()},10*1000);
});

var updateStatus = function(){
  
  lastRun = new Date();
  console.log("Updating status "+lastRun);
    
  $("#refresh").html("Last update: "+lastRun ); 
  $("#table").html(head);
  $.ajax({
    url:"status.json",
    dataType: "json", //TODO Fix "not well-formed" issue
    success:function(json){
      for (var i=0;i< json.servers.length;i++){
        var s = json.servers[i];
	
	var time = "";
	if (s.timestamp) time += s.timestamp + " ("+timeAgo(s.timestamp)+")";
	 
        var row = '<tr><td>'+s.name+'</td>'+
		  '<td class='+s.status+'>'+s.status+'</td>'+
		  '<td>'+time+'</td>'+
		  '<td>'+s.message+'</td></tr>';
        $("#table").append(row);
      }
    }
  });
}

var parseDate = function(dateString){
  var reggie = /(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})/;
  var dateArray = reggie.exec(dateString); 
  var dateObject = new Date(
      (+dateArray[1]),
      (+dateArray[2])-1, // Careful, month starts at 0!
      (+dateArray[3]),
      (+dateArray[4]),
      (+dateArray[5]),
      (+dateArray[6])
  );
  return dateObject;
}
var timeAgo = function(time){
  
  var DAY =  60*60*24,
      HOUR = 60*60,
      MINUTE = 60;
  
  var now = new Date().getTime(),
      date = parseDate(time).getTime();	
      diff = (now - date) / 1000 ; //diff in seconds
      
  if (diff > DAY) return round(diff / DAY,2) + " days";
  if (diff > HOUR ) return round(diff / HOUR,2) + " hours";
  if (diff > MINUTE ) return round(diff / MINUTE,2) + " minutes";
  else return date + " seconds";
}

var round = function(value,dec){
  return Math.round(value*10*dec)/(10*dec);
}