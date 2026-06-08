(function () {
  const measurementId = "G-S1FQBX4FK2";
  const apiSecret = "zVKxedFKQ7eyltcl31ZHCw";

  function readGaCookie() {
    const match = document.cookie.match(/_ga=GA\d+\.\d+\.([0-9]+\.[0-9]+)/);
    return match ? match[1] : null;
  }

  function randomClientId() {
    return `${Math.floor(Math.random() * 1000000000)}.${Date.now()}`;
  }

  function getClientId() {
    return readGaCookie() || randomClientId();
  }

  function collect(eventName, params) {
    const endpoint = `https://www.google-analytics.com/mp/collect?measurement_id=${encodeURIComponent(
      measurementId
    )}&api_secret=${encodeURIComponent(apiSecret)}`;
    const payload = {
      client_id: getClientId(),
      events: [
        {
          name: eventName,
          params: {
            page_title: document.title,
            page_location: window.location.href,
            page_path: window.location.pathname,
            ...params,
          },
        },
      ],
    };

    const body = JSON.stringify(payload);
    if (navigator.sendBeacon) {
      const blob = new Blob([body], { type: "application/json" });
      navigator.sendBeacon(endpoint, blob);
      return;
    }

    fetch(endpoint, {
      method: "POST",
      keepalive: true,
      headers: { "Content-Type": "application/json" },
      body,
    }).catch(() => {});
  }

  collect("page_view", {
    event_source: "mp_fallback",
  });
})();
