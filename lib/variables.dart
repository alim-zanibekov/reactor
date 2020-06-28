const REACTOR_HEADERS = {
  'User-Agent':
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.61 Safari/537.36',
  'Accept':
      'video/webm,video/ogg,video/*;q=0.9,application/ogg;q=0.7,audio/*;q=0.6,*/*;q=0.5',
  'Accept-Language': 'en-US,en;q=0.5',
  'Referer': 'http://joyreactor.cc/',
};

const REACTOR_VIDEO_HEADERS = {
  'Connection': 'keep-alive',
  'Pragma': 'no-cache',
  'Cache-Control': 'no-cache',
  'DNT': '1',
  'Cookie': 'showVideoGif3=1',
  'Accept-Encoding': 'identity;q=1, *;q=0',
  'User-Agent':
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.61 Safari/537.36',
  'Accept': '*/*',
  'Referer': 'http://joyreactor.cc/',
  'Accept-Language': 'en-US,en;q=0.5'
};

bool get isInDebugMode {
  bool inDebugMode = false;
  assert(inDebugMode = true);
  return inDebugMode;
}
