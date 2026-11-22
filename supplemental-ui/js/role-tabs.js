(() => {
  const containers = document.querySelectorAll('.openblock.role-tabs');
  if (!containers.length) return;

  containers.forEach((container, groupIdx) => {
    const panelsHost = container.querySelector(':scope > .content');
    if (!panelsHost) return;

    const panels = Array.from(panelsHost.querySelectorAll(':scope > .exampleblock.role-tab'));
    if (panels.length < 2) return;

    const tablist = document.createElement('div');
    tablist.className = 'role-tablist';
    tablist.setAttribute('role', 'tablist');
    tablist.setAttribute('aria-label', container.dataset.label || 'Guides by role');

    const tabs = panels.map((panel, idx) => {
      const titleEl = panel.querySelector(':scope > .title');
      const label = titleEl ? titleEl.textContent.trim() : `Tab ${idx + 1}`;
      if (titleEl) titleEl.remove();

      const tabId = `role-tab-${groupIdx}-${idx}`;
      const tab = document.createElement('button');
      tab.type = 'button';
      tab.className = 'role-tab-btn';
      tab.id = tabId;
      tab.setAttribute('role', 'tab');
      tab.setAttribute('aria-selected', idx === 0 ? 'true' : 'false');
      tab.tabIndex = idx === 0 ? 0 : -1;
      tab.textContent = label;
      tablist.appendChild(tab);

      panel.setAttribute('role', 'tabpanel');
      panel.setAttribute('aria-labelledby', tabId);
      if (idx === 0) {
        panel.removeAttribute('hidden');
      } else {
        panel.setAttribute('hidden', 'until-found');
      }
      return tab;
    });

    const selectTab = (index, { focus = false } = {}) => {
      const target = (index + tabs.length) % tabs.length;
      tabs.forEach((tab, i) => {
        const active = i === target;
        tab.setAttribute('aria-selected', active ? 'true' : 'false');
        tab.tabIndex = active ? 0 : -1;
        if (active) {
          panels[i].removeAttribute('hidden');
        } else {
          panels[i].setAttribute('hidden', 'until-found');
        }
      });

      const activeTab = tabs[target];
      if (focus) activeTab.focus({ preventScroll: true });
      try {
        activeTab.scrollIntoView({ block: 'nearest', inline: 'nearest', container: 'nearest' });
      } catch {
        activeTab.scrollIntoView({ block: 'nearest', inline: 'nearest' });
      }
    };

    tablist.addEventListener('click', (event) => {
      const btn = event.target.closest('[role="tab"]');
      if (!btn) return;
      const idx = tabs.indexOf(btn);
      if (idx !== -1) selectTab(idx);
    });

    tablist.addEventListener('keydown', (event) => {
      const btn = event.target.closest('[role="tab"]');
      if (!btn) return;
      const current = tabs.indexOf(btn);
      if (current === -1) return;

      if (event.key === 'ArrowRight') {
        event.preventDefault();
        selectTab(current + 1, { focus: true });
      } else if (event.key === 'ArrowLeft') {
        event.preventDefault();
        selectTab(current - 1, { focus: true });
      } else if (event.key === 'Home') {
        event.preventDefault();
        selectTab(0, { focus: true });
      } else if (event.key === 'End') {
        event.preventDefault();
        selectTab(tabs.length - 1, { focus: true });
      }
    });

    // Keep tab state synced when browser Find-in-page reveals a hidden="until-found" panel
    panelsHost.addEventListener('beforematch', (event) => {
      const matchedPanel = event.target.closest('[role="tabpanel"]');
      if (!matchedPanel) return;
      const idx = panels.indexOf(matchedPanel);
      if (idx !== -1) selectTab(idx);
    });

    // Allow deep linking via hash (#role-architect, #role-ba, #role-developer, #role-devops, #role-enduser)
    const syncFromHash = () => {
      const hash = window.location.hash.replace(/^#/, '');
      if (!hash) return;
      const idx = panels.findIndex((panel) => panel.id === hash);
      if (idx !== -1) selectTab(idx);
    };

    container.insertBefore(tablist, panelsHost);
    container.dataset.tabsReady = 'true';
    syncFromHash();
    window.addEventListener('hashchange', syncFromHash);
  });
})();
