import { useMemo, useState } from 'react';

type BuildStatus = 'In Progress' | 'Success' | 'Failed' | 'Queued';

type Script = {
  name: string;
  description: string;
  active?: boolean;
};

type BrmArea = {
  name: string;
  purpose: string;
  folder: string;
  todo: string;
};

const brmAreas: BrmArea[] = [
  {
    name: 'LXC-BRM-shared',
    purpose: 'Shared utilities, conventions, and cross-project helpers.',
    folder: '/LXC-BRM-shared',
    todo: '/LXC-BRM-shared/todo/2026-08-16.md',
  },
  {
    name: 'LXC-BRM-frameworks',
    purpose: 'Framework-specific assets and framework adapters only.',
    folder: '/LXC-BRM-frameworks',
    todo: '/LXC-BRM-frameworks/todo/2026-08-16.md',
  },
  {
    name: 'LXC-BRM-build-release',
    purpose: 'Build and release orchestration, scripts, and packaging flow.',
    folder: '/LXC-BRM-build-release',
    todo: '/LXC-BRM-build-release/todo/2026-08-16.md',
  },
  {
    name: 'LXC-BRM-worklog',
    purpose: 'Daily notes, execution logs, and progress tracking.',
    folder: '/LXC-BRM-worklog',
    todo: '/LXC-BRM-worklog/todo/2026-08-16.md',
  },
  {
    name: 'LXC-BRM-context',
    purpose: 'Context, decisions, references, and operating notes.',
    folder: '/LXC-BRM-context',
    todo: '/LXC-BRM-context/todo/2026-08-16.md',
  },
];

const history = [
  { name: 'LXC-BRM-build-release', date: 'Aug 16, 2026 2:32 PM', status: 'In Progress' as BuildStatus, duration: '00:00:47' },
  { name: 'LXC-BRM-frameworks', date: 'Aug 16, 2026 1:45 PM', status: 'Success' as BuildStatus, duration: '04:32' },
  { name: 'LXC-BRM-context', date: 'Aug 15, 2026 5:10 PM', status: 'Failed' as BuildStatus, duration: '02:15' },
  { name: 'LXC-BRM-worklog', date: 'Aug 15, 2026 4:02 PM', status: 'Success' as BuildStatus, duration: '01:28' },
];

const logs = [
  '[14:32:45] Starting work session: LXC-BRM-build-release',
  '[14:32:45] Working directory: /Users/user/workspace/LXC-BRM',
  '[14:32:45] ------------------------------------------------------------',
  '[14:32:45] Scanning BRM folders...',
  '[14:32:48] ✓ Found LXC-BRM-shared',
  '[14:32:48] ✓ Found LXC-BRM-frameworks',
  '[14:32:53] ✓ Found LXC-BRM-build-release',
  '[14:32:55] ✓ Found LXC-BRM-worklog',
  '[14:33:02] ✓ Found LXC-BRM-context',
  '[14:33:22] ▶ Loaded todo file: 2026-08-16.md',
  '[14:33:28] ▶ Indexed README tracking table',
  '[14:33:32] ✓ BRM layout ready',
  '[14:33:32] 📦 Output: /LXC-BRM/README.md',
  '[14:33:32] ✓ Session completed in 46.87s',
];

export function App() {
  const [selectedRepo] = useState('LXC-BRM');
  const [theme] = useState<'dark' | 'light'>('dark');
  const statusClass = useMemo(() => (theme === 'dark' ? 'theme-dark' : 'theme-light'), [theme]);

  return (
    <div className={`shell ${statusClass}`}>
      <aside className="sidebar">
        <div className="sidebar-section">
          <div className="section-title">BRM Areas</div>
          <button className="icon-button">+</button>
        </div>

        <div className="repo-card active">
          <div>
            <div className="repo-name">{selectedRepo}</div>
            <div className="repo-path">Repo root and top-level container</div>
          </div>
          <span className="dot dot-green" />
        </div>

        <div className="repo-card">
          <div>
            <div className="repo-name">LXC-BRM-shared</div>
            <div className="repo-path">Shared helpers and conventions</div>
          </div>
          <span className="dot dot-green" />
        </div>

        <div className="divider" />

        <div className="section-title">Area Index</div>
        {brmAreas.map((area) => (
          <div className="recent-row" key={area.name}>
            <div>
              <div className="repo-name small">{area.name}</div>
              <div className="repo-path">{area.purpose}</div>
              <div className="opened">{area.todo}</div>
            </div>
            <span className="trash">•</span>
          </div>
        ))}

        <button className="open-repo">Open Repository...</button>
        <button className="preferences">Preferences</button>
      </aside>

      <main className="main">
        <header className="topbar">
          <div>
            <div className="project-title">LXC-BRM <span className="badge">Loaded</span></div>
            <div className="project-path">Root workspace that hosts shared, frameworks, build-release, worklog, and context folders.</div>
          </div>
          <div className="actions">
            <button className="ghost">Reveal in Finder</button>
            <button className="ghost">⧉</button>
            <button className="ghost">⟲ Refresh</button>
          </div>
        </header>

        <nav className="tabs">
          {['Build', 'Logs', 'History', 'Overview', 'Settings'].map((tab, idx) => (
            <button key={tab} className={idx === 0 ? 'tab active' : 'tab'}>{tab}</button>
          ))}
        </nav>

        <section className="scripts panel">
          <div className="panel-header">
            <h2>Defined Folders</h2>
            <span>Auto-detected from <strong>/LXC-BRM-*</strong></span>
          </div>
          <div className="script-grid">
            {brmAreas.map((area, index) => (
              <button className={index === 0 ? 'script-card active' : 'script-card'} key={area.name}>
                <div className="script-icon">{'>'}_</div>
                <div className="script-meta">
                  <div className="script-name">{area.name}</div>
                  <div className="script-desc">{area.purpose}</div>
                </div>
                <div className="play">{index === 0 ? '▶' : '▸'}</div>
              </button>
            ))}
          </div>
          <div className="panel-note">Every area gets a dated todo file: <strong>YYYY-MM-DD.md</strong>, with 2026-08-16.md as the starter example.</div>
        </section>

        <section className="log panel">
          <div className="panel-header">
            <h2>Worklog Preview</h2>
            <span className="running"><i /> Running: 2026-08-16.md</span>
            <div className="inline-actions">
              <button className="stop small">Stop</button>
              <button className="ghost small">Clear</button>
            </div>
          </div>
          <pre className="console">{logs.join('\n')}</pre>
          <div className="footer-row">
            <label><input type="checkbox" defaultChecked /> Auto-scroll</label>
            <span>Lines: 248</span>
            <button className="ghost small">Save Log</button>
          </div>
        </section>
      </main>

      <aside className="right-rail">
        <section className="panel status-panel">
          <h3>BRM Status</h3>
          <div className="status-card">
            <div className="spinner" />
            <div>
              <div className="status-title">In Progress</div>
              <div className="status-sub">LXC-BRM-build-release</div>
              <div className="status-sub">Running for 00:00:47</div>
            </div>
          </div>
          <div className="status-metrics">
            <div><span>Started At</span><strong>Aug 16, 2026 2:32:45 PM</strong></div>
            <div><span>Duration</span><strong>00:00:47</strong></div>
            <div><span>Status</span><strong className="blue">In Progress</strong></div>
          </div>
          <button className="stop full">Stop Build</button>
        </section>

        <section className="panel history-panel">
          <div className="panel-header compact">
            <h3>Work History</h3>
            <button className="ghost small">View All</button>
          </div>
          <div className="history-list">
            {history.map((item) => (
              <div className="history-item" key={`${item.name}-${item.date}`}>
                <div className={`history-dot ${item.status.toLowerCase()}`} />
                <div className="history-info">
                  <div className="history-name">{item.name}</div>
                  <div className="history-date">{item.date}</div>
                </div>
                <div className={`history-status ${item.status.toLowerCase()}`}>{item.status}</div>
                <div className="history-duration">{item.duration}</div>
              </div>
            ))}
          </div>
        </section>

        <section className="panel actions-panel">
          <h3>Quick Actions</h3>
          <button className="action-btn">Open BRM Root</button>
          <button className="action-btn">Open Worklog Todo</button>
        </section>
      </aside>

      <footer className="footer">
        <span>Repository: LXC-BRM</span>
        <span>Branch: main</span>
        <span>Platform: macOS</span>
        <span className="green">Auto-detect: Enabled</span>
      </footer>
    </div>
  );
}
