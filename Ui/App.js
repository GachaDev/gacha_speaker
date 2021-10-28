$(document).ready(function() {
  window.addEventListener('message', function(event) {
    if (event.data.open) {
      $('.Main').show();
    }
    if (event.data.stop) {
      isPlaying = false;
      stop();
    }
    if (event.data.volume) {
      player.setVolume(event.data.volume);
    }
    if (event.data.play) {
      isPlaying = true;
      event.data.song = event.data.song.replace('https://www.youtube.com/watch?v=','');
      event.data.song = event.data.song.replace('https://youtu.be/','');
      play(event.data.song);
      var nowTime = GetTime()
      var diferenceTime = nowTime + 350 - event.data.time
      var seconds = diferenceTime / 1000
      setTimeout(() => {
        player.seekTo(seconds)
      }, 350);
    }
  });
  $(document).on('click','.play',function(event){
    if (isPlaying) {
      // Hacemos post
      $.post('https://gacha_speaker/stopMusic');
    } else {
      $.post('https://gacha_speaker/playMusic', JSON.stringify({ url: $("#url").val(), time: GetTime() }));
    }
  });
  document.onkeydown = function(data) {
    if (data.which == 27) {
      $.post('https://gacha_speaker/exit');
      $('.Main').hide();
    }
    if (data.which === 13) {
      $.post('https://gacha_speaker/playMusic', JSON.stringify({ url: $("#url").val(), time: GetTime() }));
    }
  };
});

//YouTube IFrame API player. Source: https://developers.google.com/youtube/iframe_api_reference?hl=es
var player;
var isPlaying = false;

//Create DOM elements for the player.
var tag = document.createElement("script");
tag.src = "https://www.youtube.com/iframe_api";

var firstScriptTag  = document.getElementsByTagName("script")[0];
firstScriptTag .parentNode.insertBefore(tag, firstScriptTag);

function GetTime() {
  var time = new Date();
  var exactTime = time.getMonth() * 30 * 24 * 60 * 60 * 1000 + time.getDay() * 24 * 60 * 60 * 1000 + time.getHours() * 60 * 60 * 1000 + time.getMinutes() * 60 * 1000 + time.getSeconds() * 1000 + time.getMilliseconds()
  return exactTime
}

function onYouTubeIframeAPIReady() {
  player = new YT.Player("player", {
    playerVars: {
      autoplay: 0,
      controls: 0,
      disablekb: 1,
      enablejsapi: 1,
    },
    events: {
      onReady: onPlayerReady,
      onStateChange: onPlayerStateChange,
    },
  });
}

function onPlayerReady(event) {
  player.setVolume(50);
}

function onPlayerStateChange(event) {
  if (event.data == YT.PlayerState.PLAYING) {
    isPlaying = true;
    $('.playing').show();
    $("#player").css({ 'visibility' : 'visible', 'margin-bottom': '10%' });
    $(".Main").css({ 'top' : '23%' });
  }

  if (event.data == YT.PlayerState.ENDED) {
    isPlaying = false;
    stop();
  }
}

function play(id) {
  player.loadVideoById(id, 0, "...");
  player.playVideo();
  $(".play").css({ 'border-width' : '0px 0 0px 60px' });
  $(".Main").css({ 'top' : '23%' });
  var url = 'https://www.youtube.com/watch?v=' + id;
  
  $.getJSON('https://noembed.com/embed',
    {format: 'json', url: url}, function (data) {
      $('.playing').text(data.title)
      $('.playing').show();
    }
  );
}

function stop() {
  player.stopVideo();
  $('.playing').hide();
  $(".play").css({ 'border-width' : '37px 0 37px 60px' });
  $("#player").css({ 'visibility' : 'hidden', 'margin-bottom': '-50%' });
  $(".Main").css({ 'top' : '35%' });
}

function setVolume(volume) {
  player.setVolume(volume);
}

