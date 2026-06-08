(function () {
  const endpoints = [
    "https://mayaway.cc/collect",
    "https://faraway-ga4-collector.ccfilmsichao.workers.dev/collect",
  ];
  const clientIdKey = "faraway_analytics_client_id";

  function getClientId() {
    try {
      const existing = localStorage.getItem(clientIdKey);
      if (existing && existing.length > 0) {
        return existing;
      }
      const generated =
        (crypto.randomUUID && crypto.randomUUID()) ||
        `${Date.now()}.${Math.random().toString(16).slice(2)}`;
      localStorage.setItem(clientIdKey, generated);
      return generated;
    } catch (error) {
      return `${Date.now()}.${Math.random().toString(16).slice(2)}`;
    }
  }

  async function postAnalytics(endpoint, payload) {
    const body = JSON.stringify(payload);
    const response = await fetch(endpoint, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body,
      keepalive: true,
      mode: "cors",
    });

    return response.ok;
  }

  async function sendAnalytics() {
    const payload = {
      client_id: getClientId(),
      page_location: location.href,
      page_title: document.title,
      page_referrer: document.referrer || "direct",
    };

    for (const endpoint of endpoints) {
      try {
        if (await postAnalytics(endpoint, payload)) {
          return;
        }
      } catch (error) {
        continue;
      }
    }
  }

  sendAnalytics().catch(() => {});
})();
