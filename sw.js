/* Knight Warriors Club — service worker.
   Job 1: receive Web Push messages (club broadcasts) and show them as
   device notifications, even when the site is closed.
   It deliberately does NOT cache pages or intercept navigation — the
   site always loads fresh from the network. */

self.addEventListener('push', function (event) {
  var data = {
    title: 'Knight Warriors Club',
    body: 'You have a new club message.',
    link: 'https://knightwarriorsclub.com/#profile/inbox'
  };
  try {
    if (event.data) {
      var j = event.data.json();
      if (j.title) data.title = j.title;
      if (j.body) data.body = j.body;
      if (j.link) data.link = j.link;
    }
  } catch (e) { /* keep defaults */ }
  event.waitUntil(
    self.registration.showNotification(data.title, {
      body: data.body,
      icon: '/assets/logo.jpg',
      badge: '/assets/logo.jpg',
      tag: 'kwc-broadcast',
      data: { link: data.link }
    })
  );
});

self.addEventListener('notificationclick', function (event) {
  event.notification.close();
  var link = (event.notification.data && event.notification.data.link) ||
    'https://knightwarriorsclub.com/#profile/inbox';
  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function (list) {
      for (var i = 0; i < list.length; i++) {
        if (list[i].url.indexOf('knightwarriorsclub.com') !== -1) {
          list[i].navigate(link);
          return list[i].focus();
        }
      }
      return self.clients.openWindow(link);
    })
  );
});
