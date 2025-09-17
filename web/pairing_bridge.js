// Global pairing bridge for cross-browser pairing
// This stores pairing codes in a way that's accessible across browsers

window.pairingBridge = {
  // Store a pairing code
  storeCode: function(code, phoneNumber, displayName) {
    const data = {
      phone: phoneNumber,
      name: displayName || phoneNumber,
      timestamp: new Date().toISOString()
    };

    // Store in localStorage with a specific prefix
    localStorage.setItem('willingtree_pairing_' + code, JSON.stringify(data));

    // Clean up old codes
    this.cleanupOldCodes();

    return true;
  },

  // Retrieve and validate a pairing code
  getCode: function(code) {
    const key = 'willingtree_pairing_' + code;
    const data = localStorage.getItem(key);

    if (data) {
      const parsed = JSON.parse(data);

      // Check if code is not too old (10 minutes)
      const timestamp = new Date(parsed.timestamp);
      const now = new Date();
      const diffMinutes = (now - timestamp) / (1000 * 60);

      if (diffMinutes <= 10) {
        // Remove the code after successful retrieval
        localStorage.removeItem(key);
        return parsed;
      } else {
        // Code is too old, remove it
        localStorage.removeItem(key);
      }
    }

    return null;
  },

  // Clean up codes older than 10 minutes
  cleanupOldCodes: function() {
    const now = new Date();
    const keys = Object.keys(localStorage);

    keys.forEach(key => {
      if (key.startsWith('willingtree_pairing_')) {
        try {
          const data = JSON.parse(localStorage.getItem(key));
          const timestamp = new Date(data.timestamp);
          const diffMinutes = (now - timestamp) / (1000 * 60);

          if (diffMinutes > 10) {
            localStorage.removeItem(key);
          }
        } catch (e) {
          // Invalid data, remove it
          localStorage.removeItem(key);
        }
      }
    });
  },

  // List all active codes (for debugging)
  listCodes: function() {
    const codes = {};
    const keys = Object.keys(localStorage);

    keys.forEach(key => {
      if (key.startsWith('willingtree_pairing_')) {
        const code = key.replace('willingtree_pairing_', '');
        codes[code] = JSON.parse(localStorage.getItem(key));
      }
    });

    return codes;
  }
};