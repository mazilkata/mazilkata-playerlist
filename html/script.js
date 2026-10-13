(function() {
  'use strict';

  // State Management
  const isEnvBrowser = !window.invokeNative;
  let isVisible = isEnvBrowser;
  let activeTab = 'online';
  let searchQuery = '';
  let onlinePlayers = [];
  let disconnectedPlayers = [];
  let mySource = null;
  let canSeeIdentifiers = false;
  let showPing = true;
  let inAreaCount = 0;
  let talkingMap = {};
  let openKey = 'F6';

  let locale = {
    title: 'PLAYER LIST',
    subtitleOnline: 'ONLINE',
    subtitleDisconnected: 'DISCONNECTED',
    statTotalOnline: 'PLAYER LIST',
    statInArea: 'PLAYERS IN AREA',
    tabOnline: 'ONLINE',
    tabDisconnected: 'DISCONNECTED',
    searchPlaceholder: 'Search players by name or ID...',
    slotPrefix: 'Slot:',
    pingUnit: 'ms',
    youBadge: 'YOU',
    talking: 'TALKING',
    leftJustNow: 'left just now',
    leftMinutesAgo: 'left %d min ago',
    leftHoursAgo: 'left %d hr ago',
    leftDaysAgo: 'left %d d ago',
    noOnlinePlayers: 'No players currently online',
    noDisconnectedPlayers: 'No recently disconnected players',
    noSearchResults: 'No matching players found'
  };

  // Mock data for browser preview
  const MOCK_ONLINE = [
    { id: 1, name: 'quick.', ping: 14, identifier: 'steam:110000105b630df' },
    { id: 2, name: 'bulgarina', ping: 22, identifier: 'steam:1100001035548df' }
  ];

  const MOCK_DISCONNECTED = [
    { id: 8, name: 'ShadowHunter', leftAt: Math.floor(Date.now() / 1000) - 120, identifier: 'steam:110000101234567' }
  ];

  // DOM Elements
  const viewport = document.getElementById('playerlist-viewport');
  const headerTitle = document.getElementById('header-title');
  const headerSubtitle = document.getElementById('header-subtitle');
  const statTotalLabel = document.getElementById('stat-total-label');
  const statTotalNumber = document.getElementById('stat-total-number');
  const statAreaLabel = document.getElementById('stat-area-label');
  const statAreaNumber = document.getElementById('stat-area-number');
  const tabOnlineBtn = document.getElementById('tab-online');
  const tabDisconnectedBtn = document.getElementById('tab-disconnected');
  const btnKeyQ = document.getElementById('btn-key-q');
  const btnKeyE = document.getElementById('btn-key-e');
  const searchInput = document.getElementById('search-input');
  const searchClearBtn = document.getElementById('search-clear-btn');
  const listContainer = document.getElementById('player-list-scrollable');

  // NUI Fetch Utility
  function fetchNui(eventName, data = {}) {
    const resourceName = window.GetParentResourceName ? window.GetParentResourceName() : 'mazilkata-playerlist';
    return fetch(`https://${resourceName}/${eventName}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data)
    }).catch(() => {});
  }

  // HTML escaping for safety
  function escapeHtml(str) {
    if (typeof str !== 'string') return '';
    return str
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  }

  // Format relative disconnected time
  function formatLeftTime(leftAtEpoch) {
    if (!leftAtEpoch) return locale.leftJustNow || 'left just now';
    const now = Math.floor(Date.now() / 1000);
    const diffSec = Math.max(0, now - leftAtEpoch);
    const diffMin = Math.floor(diffSec / 60);

    if (diffMin < 1) {
      return locale.leftJustNow || 'left just now';
    } else if (diffMin < 60) {
      const tmpl = locale.leftMinutesAgo || 'left %d min ago';
      return tmpl.replace('%d', diffMin);
    } else if (diffMin < 1440) {
      const diffHours = Math.floor(diffMin / 60);
      const tmpl = locale.leftHoursAgo || 'left %d hr ago';
      return tmpl.replace('%d', diffHours);
    } else {
      const diffDays = Math.floor(diffMin / 1440);
      const tmpl = locale.leftDaysAgo || 'left %d d ago';
      return tmpl.replace('%d', diffDays);
    }
  }

  // Apply Locale strings to DOM
  function updateLocaleLabels() {
    if (headerTitle) headerTitle.textContent = locale.title || 'PLAYER LIST';
    if (statTotalLabel) statTotalLabel.textContent = locale.statTotalOnline || 'PLAYER LIST';
    if (statAreaLabel) statAreaLabel.textContent = locale.statInArea || 'PLAYERS IN AREA';
    if (tabOnlineBtn) tabOnlineBtn.textContent = locale.tabOnline || 'ONLINE';
    if (tabDisconnectedBtn) tabDisconnectedBtn.textContent = locale.tabDisconnected || 'DISCONNECTED';
    if (searchInput) searchInput.placeholder = locale.searchPlaceholder || 'Search players by name or ID...';
    updateHeaderSubtitle();
  }

  function updateHeaderSubtitle() {
    if (!headerSubtitle) return;
    if (activeTab === 'online') {
      headerSubtitle.textContent = locale.subtitleOnline || 'ONLINE';
    } else {
      headerSubtitle.textContent = locale.subtitleDisconnected || 'DISCONNECTED';
    }
  }

  // Switch Active Tab
  function setActiveTab(newTab) {
    if (activeTab === newTab) return;
    activeTab = newTab;

    if (activeTab === 'online') {
      tabOnlineBtn.classList.add('active');
      tabDisconnectedBtn.classList.remove('active');
    } else {
      tabDisconnectedBtn.classList.add('active');
      tabOnlineBtn.classList.remove('active');
    }

    updateHeaderSubtitle();
    renderPlayerList();
  }

  // Close the menu
  function closeMenu() {
    isVisible = false;
    viewport.style.display = 'none';
    fetchNui('close');
  }

  // Open the menu
  function openMenu(data) {
    isVisible = true;
    viewport.style.display = 'flex';

    if (data.online) onlinePlayers = data.online;
    if (data.disconnected) disconnectedPlayers = data.disconnected;
    if (data.mySource !== undefined) mySource = data.mySource;
    if (data.canSeeIdentifiers !== undefined) canSeeIdentifiers = data.canSeeIdentifiers;
    if (data.showPing !== undefined) showPing = data.showPing;
    if (typeof data.openKey === 'string') openKey = data.openKey;
    if (data.showSearch !== undefined) {
      const sw = document.querySelector('.search-bar-wrapper');
      if (sw) sw.style.display = data.showSearch ? 'block' : 'none';
    }
    if (data.locale) {
      locale = Object.assign(locale, data.locale);
      updateLocaleLabels();
    }

    searchQuery = '';
    searchInput.value = '';
    searchClearBtn.style.display = 'none';

    statTotalNumber.textContent = onlinePlayers.length;
    renderPlayerList();
  }

  const USER_ICON_SVG = `
    <svg class="avatar-user-icon" viewBox="0 0 24 24" fill="currentColor">
      <path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/>
    </svg>`;

  // Only images from Discord / Cfx.re forum CDNs are accepted as avatars
  function safeAvatarUrl(url) {
    if (typeof url !== 'string') return null;
    return /^https:\/\/(cdn\.discordapp\.com|forum\.cfx\.re|forums\.cfx\.re|[a-z0-9-]+\.discourse-cdn\.com)\//.test(url) ? url : null;
  }

  function avatarInner(p) {
    const url = safeAvatarUrl(p.avatar);
    if (!url) return USER_ICON_SVG;
    return `<img class="avatar-img" src="${escapeHtml(url)}" alt="" draggable="false" referrerpolicy="no-referrer">`;
  }

  // If an avatar fails to load, fall back to the default user icon
  listContainer.addEventListener('error', (e) => {
    const img = e.target;
    if (img && img.classList && img.classList.contains('avatar-img')) {
      img.parentElement.innerHTML = USER_ICON_SVG;
    }
  }, true);

  const TALKING_HTML = () => `
    <span class="talking-indicator" title="${escapeHtml(locale.talking || 'Talking')}">
      <span class="voice-bar bar-1"></span>
      <span class="voice-bar bar-2"></span>
      <span class="voice-bar bar-3"></span>
    </span>`;

  // Patch talking state on existing rows WITHOUT rebuilding the list (prevents flicker)
  function syncTalkingRows() {
    if (activeTab !== 'online') return;
    listContainer.querySelectorAll('.player-row:not(.disconnected-row)').forEach(row => {
      const talking = !!talkingMap[row.dataset.id];
      const has = row.classList.contains('is-talking');
      if (talking === has) return;
      row.classList.toggle('is-talking', talking);
      const line = row.querySelector('.player-name-line');
      if (!line) return;
      if (talking) {
        line.insertAdjacentHTML('beforeend', TALKING_HTML());
      } else {
        const ind = line.querySelector('.talking-indicator');
        if (ind) ind.remove();
      }
    });
  }

  // Render the player rows matching screenshot exactly
  function renderPlayerList() {
    const isOnline = activeTab === 'online';
    const rawList = isOnline ? onlinePlayers : disconnectedPlayers;
    const q = searchQuery.trim().toLowerCase();

    // Filter
    let filtered = rawList;
    if (q) {
      filtered = rawList.filter(p => {
        const name = (p.name || '').toLowerCase();
        const id = String(p.id);
        const ident = (p.identifier || '').toLowerCase();
        return name.includes(q) || id.includes(q) || ident.includes(q);
      });
    }

    // Sort by Slot ID
    filtered.sort((a, b) => Number(a.id) - Number(b.id));

    // Handle Empty State
    if (filtered.length === 0) {
      let emptyMsg = isOnline
        ? (locale.noOnlinePlayers || 'No players currently online')
        : (locale.noDisconnectedPlayers || 'No recently disconnected players');
      if (q) {
        emptyMsg = locale.noSearchResults || 'No matching players found';
      }

      listContainer.innerHTML = `
        <div class="empty-list-container">
          <svg class="empty-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6">
            <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
            <circle cx="9" cy="7" r="4" />
            <line x1="23" y1="11" x2="17" y2="11" />
          </svg>
          <span class="empty-text">${escapeHtml(emptyMsg)}</span>
        </div>
      `;
      return;
    }

    // Build Row HTML
    let html = '';
    filtered.forEach(p => {
      const pId = p.id;
      const safeName = escapeHtml(p.name || `Player ${pId}`);
      const isTalking = isOnline && !!talkingMap[pId];

      if (isOnline) {
        const pingVal = p.ping !== undefined && p.ping !== null ? p.ping : 0;
        const pingUnit = locale.pingUnit || 'ms';

        html += `
          <div class="player-row ${isTalking ? 'is-talking' : ''}" data-id="${pId}">
            <div class="player-avatar-square">${avatarInner(p)}</div>
            <div class="player-details">
              <div class="player-name-line">
                <span class="player-name">${safeName}</span>
${isTalking ? TALKING_HTML() : ''}
              </div>
              <div class="player-sub-line">
                <span class="player-slot-text">
                  ${escapeHtml(locale.slotPrefix || 'Slot:')} <span class="slot-number">${pId}</span>
                </span>
              </div>
            </div>
            ${showPing ? `
              <div class="player-ping-badge">
                <span class="ping-val">${pingVal}${pingUnit}</span>
              </div>
            ` : ''}
          </div>
        `;
      } else {
        const timeFormatted = formatLeftTime(p.leftAt);

        html += `
          <div class="player-row disconnected-row" data-id="${pId}">
            <div class="player-avatar-square disconnected-avatar">${avatarInner(p)}</div>
            <div class="player-details">
              <div class="player-name-line">
                <span class="player-name disconnected-name">${safeName}</span>
              </div>
              <div class="player-sub-line">
                <span class="player-slot-text">
                  ${escapeHtml(locale.slotPrefix || 'Slot:')} <span class="slot-number">${pId}</span>
                </span>
              </div>
            </div>
            <div class="disco-time-badge">
              <span class="disco-time-text">${escapeHtml(timeFormatted)}</span>
            </div>
          </div>
        `;
      }
    });

    listContainer.innerHTML = html;
  }

  // Update pings in real-time
  function updatePings(pings) {
    if (!pings) return;
    onlinePlayers.forEach(p => {
      if (pings[p.id] !== undefined) {
        p.ping = pings[p.id];
      }
    });
    if (activeTab === 'online') {
      const pingUnit = locale.pingUnit || 'ms';
      Object.keys(pings).forEach(sId => {
        const row = listContainer.querySelector(`.player-row[data-id="${sId}"] .ping-val`);
        if (row) {
          row.textContent = `${pings[sId]}${pingUnit}`;
        }
      });
    }
  }

  // Event Listeners for Tab Switching
  tabOnlineBtn.addEventListener('click', () => setActiveTab('online'));
  tabDisconnectedBtn.addEventListener('click', () => setActiveTab('disconnected'));
  btnKeyQ.addEventListener('click', () => setActiveTab(activeTab === 'online' ? 'disconnected' : 'online'));
  btnKeyE.addEventListener('click', () => setActiveTab(activeTab === 'online' ? 'disconnected' : 'online'));

  // Search Input Handlers
  searchInput.addEventListener('input', (e) => {
    searchQuery = e.target.value;
    searchClearBtn.style.display = searchQuery ? 'block' : 'none';
    renderPlayerList();
  });

  searchClearBtn.addEventListener('click', () => {
    searchQuery = '';
    searchInput.value = '';
    searchClearBtn.style.display = 'none';
    searchInput.focus();
    renderPlayerList();
  });

  // Global Keyboard Listener
  window.addEventListener('keydown', (e) => {
    if (!isVisible) return;

    if (e.key === 'Escape' || e.key.toLowerCase() === openKey.toLowerCase()) {
      e.preventDefault();
      closeMenu();
      return;
    }

    // Do NOT trigger tab switches if user is actively typing in the search bar
    const activeEl = document.activeElement;
    if (activeEl && (activeEl.tagName === 'INPUT' || activeEl.tagName === 'TEXTAREA')) {
      return;
    }

    if (e.key === 'q' || e.key === 'Q') {
      e.preventDefault();
      setActiveTab('online');
    } else if (e.key === 'e' || e.key === 'E') {
      e.preventDefault();
      setActiveTab('disconnected');
    }
  });

  // Window Message Listener (from Lua client)
  window.addEventListener('message', (event) => {
    const item = event.data;
    if (!item || !item.action) return;

    switch (item.action) {
      case 'open':
        openMenu(item.data || {});
        break;

      case 'close':
        isVisible = false;
        viewport.style.display = 'none';
        break;

      case 'setLocale':
        if (item.locale) {
          locale = Object.assign(locale, item.locale);
          updateLocaleLabels();
          renderPlayerList();
        }
        break;

      case 'updateLiveStats':
        if (item.areaCount !== undefined) {
          inAreaCount = item.areaCount;
          statAreaNumber.textContent = inAreaCount;
        }
        if (item.talking) {
          talkingMap = item.talking;
          syncTalkingRows();
        }
        break;

      case 'playerJoined':
        if (item.player) {
          onlinePlayers = onlinePlayers.filter(p => p.id !== item.player.id);
          onlinePlayers.push(item.player);
          statTotalNumber.textContent = onlinePlayers.length;
          if (activeTab === 'online') renderPlayerList();
        }
        break;

      case 'playerLeft':
        if (item.id) {
          onlinePlayers = onlinePlayers.filter(p => p.id !== item.id);
          statTotalNumber.textContent = onlinePlayers.length;
          if (item.disconnectedRecord) {
            disconnectedPlayers.unshift(item.disconnectedRecord);
          }
          renderPlayerList();
        }
        break;

      case 'playerUpdated':
        if (item.player) {
          const idx = onlinePlayers.findIndex(p => p.id === item.player.id);
          if (idx !== -1) {
            onlinePlayers[idx] = Object.assign(onlinePlayers[idx], item.player);
          } else {
            onlinePlayers.push(item.player);
          }
          if (activeTab === 'online') renderPlayerList();
        }
        break;

      case 'updatePings':
        updatePings(item.pings);
        break;

      case 'syncDisconnected':
        if (item.disconnected) {
          disconnectedPlayers = item.disconnected;
          if (activeTab === 'disconnected') renderPlayerList();
        }
        break;
    }
  });

  // Ready signal to Lua
  fetchNui('ready');

  // If in browser outside of FiveM, initialize mock preview immediately
  if (isEnvBrowser) {
    onlinePlayers = MOCK_ONLINE;
    disconnectedPlayers = MOCK_DISCONNECTED;
    mySource = 1;
    canSeeIdentifiers = true;
    openMenu({
      online: MOCK_ONLINE,
      disconnected: MOCK_DISCONNECTED,
      mySource: 1,
      canSeeIdentifiers: true
    });
  }
})();
