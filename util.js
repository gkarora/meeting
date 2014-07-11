$(document).on("pageshow", "#selectTime", function(){
    setToday();
    $("#startTime").on("blur", function(){
        timeArr = $("#startTime").val().split(':');
        timeArr[0] = checkZero (parseInt(timeArr[0]) + 1);
        endTime = timeArr[0]+ ':' + timeArr[1];
        $("#endTime").val(endTime);
    });
    $("#processed").on("popupbeforeposition", function(){
        $(".sTime").empty();
        $(".eTime").empty();
        convertTZ();
        $("#edit").on("click", function(){
            $("#processed").popup("close");
        });
    });
});

function setToday(){
    today=getToday();
    $("#date").val(today[0]+'-'+today[1]+'-'+today[2]);
    $("#startTime").val(today[3]+':'+today[4]);
    $("#endTime").val((today[3]+1)+':'+today[4]);
}

function getToday(){	
	date = new Date();
	d = date.getDate();
	m = date.getMonth()+1;
	y = date.getFullYear();
    n = date.getHours();
    mi = date.getMinutes();

    m = checkZero(m);
    d = checkZero(d);
    n = checkZero(n);
    mi = checkZero(mi);
  return [y,m,d,n,mi];
}

function checkZero (x){
   if (x<10)
    return "0"+x;
   else
    return x;
}

function convertTZ(){
    tz1 = date.getTimezoneOffset();
    tz2 = $("#DropDownTimezone").val()*60;

    $startTimeTZ1 = $("#startTime");
    $endTimeTZ1 = $("#endTime");
    
    timediff = tz1+parseInt(tz2);//hours
    timediffMS = timediff*60*1000;
    
    day = $("#date").val().split('-');
    day = day.map(function(x){return parseInt(x)});
    day[1]=day[1]-1; //months start at 0
    
    sDates = convertToDate($startTimeTZ1, day, timediffMS);
    eDates = convertToDate($endTimeTZ1, day, timediffMS);

    setConfirmation (sDates, eDates);
    setEmail(sDates, eDates);
}

function setConfirmation(sDates, eDates){ 
    $("#tz1 .sTime").append(sDates[0].toDateString() 
        + "<text class='important'> @ </text>"
        + sDates[0].toLocaleTimeString());
    $("#tz1 .eTime").append(eDates[0].toDateString() 
        + "<text class='important'> @ </text>"
        + eDates[0].toLocaleTimeString());
    $("#tz2 .sTime").append(sDates[1].toDateString() 
        + "<text class='important'> @ </text>"
        + sDates[1].toLocaleTimeString());
    $("#tz2 .eTime").append(eDates[1].toDateString() 
        + "<text class='important'> @ </text>"
        + eDates[1].toLocaleTimeString());
}

function convertToDate(elem, day, timediffMS){
    timeArr = elem.val().split(':');
    timeArr = timeArr.map(function(x){return parseInt(x)});
    dateOb = new Date(day[0],day[1],day[2],timeArr[0],timeArr[1]);
    dateTZ2 = dateOb.getTime()+timediffMS;
    dateObTZ2 = new Date (dateTZ2);

    return [dateOb, dateObTZ2];
}

function setEmail(sDates, eDates){
    subject = "Meeting Request";    
    email = 
        "Hello,\n"+
        "Would you like to meet me on "+sDates[1].toDateString() 
        + " at " + sDates[1].toLocaleTimeString() + " to "
        + eDates[1].toDateString() + " at " + eDates[1].toLocaleTimeString()
        + " your time?\n\n"+
        "Thanks!";
    uriSubject = encodeURIComponent(subject);
    uriEmail = encodeURIComponent(email);
    $("#emailLink").attr('href', "mailto:?subject="+uriSubject+"&body="+uriEmail);
}
