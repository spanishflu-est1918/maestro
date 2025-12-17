// Maestro Dashboard JavaScript

class MaestroDashboard {
    constructor() {
        this.currentTaskFilter = 'all';
        this.refreshInterval = 5000; // 5 seconds
        this.init();
    }

    async init() {
        this.setupEventListeners();
        await this.loadAll();
        this.startAutoRefresh();
    }

    setupEventListeners() {
        // Task filter tabs
        document.querySelectorAll('.tab').forEach(tab => {
            tab.addEventListener('click', (e) => {
                document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
                e.target.classList.add('active');
                this.currentTaskFilter = e.target.dataset.status;
                this.loadTasks();
            });
        });
    }

    async loadAll() {
        await Promise.all([
            this.loadSpaces(),
            this.loadTasks(),
            this.loadDocuments()
        ]);
    }

    async loadSpaces() {
        try {
            const spaces = await this.fetchSpaces();
            this.renderSpaces(spaces);
        } catch (error) {
            this.renderError('spaces-list', 'Failed to load spaces');
            console.error('Error loading spaces:', error);
        }
    }

    async loadTasks() {
        try {
            const tasks = await this.fetchTasks(this.currentTaskFilter);
            this.renderTasks(tasks);
        } catch (error) {
            this.renderError('tasks-list', 'Failed to load tasks');
            console.error('Error loading tasks:', error);
        }
    }

    async loadDocuments() {
        try {
            const documents = await this.fetchDocuments();
            this.renderDocuments(documents);
        } catch (error) {
            this.renderError('documents-list', 'Failed to load documents');
            console.error('Error loading documents:', error);
        }
    }

    // API Methods (mock for now, will connect to actual daemon later)
    async fetchSpaces() {
        // TODO: Replace with actual API call to daemon
        // For now, return empty array (will be populated when API is ready)
        return [];
    }

    async fetchTasks(status) {
        // TODO: Replace with actual API call to daemon
        return [];
    }

    async fetchDocuments() {
        // TODO: Replace with actual API call to daemon
        return [];
    }

    // Render Methods
    renderSpaces(spaces) {
        const container = document.getElementById('spaces-list');

        if (spaces.length === 0) {
            container.innerHTML = '<div class="empty">No spaces yet</div>';
            return;
        }

        container.innerHTML = spaces.map(space => `
            <div class="space-card" style="border-left-color: ${space.color}">
                <div class="space-name">${this.escapeHtml(space.name)}</div>
                ${space.path ? `<div class="space-meta">
                    <span>📁 ${this.escapeHtml(space.path)}</span>
                </div>` : ''}
                ${space.tags && space.tags.length > 0 ? `
                    <div class="space-tags">
                        ${space.tags.map(tag => `<span class="tag">${this.escapeHtml(tag)}</span>`).join('')}
                    </div>
                ` : ''}
            </div>
        `).join('');
    }

    renderTasks(tasks) {
        const container = document.getElementById('tasks-list');

        if (tasks.length === 0) {
            container.innerHTML = '<div class="empty">No tasks to show</div>';
            return;
        }

        container.innerHTML = tasks.map(task => `
            <div class="task-card">
                <div class="task-header">
                    <div class="task-title">${this.escapeHtml(task.title)}</div>
                    ${task.priority && task.priority !== 'none' ? `
                        <span class="task-priority priority-${task.priority}">${task.priority}</span>
                    ` : ''}
                </div>
                ${task.description ? `
                    <div class="task-description">${this.escapeHtml(task.description)}</div>
                ` : ''}
                <div class="task-meta">
                    <span class="task-status status-${task.status}">${this.formatStatus(task.status)}</span>
                    <span>Updated ${this.formatDate(task.updatedAt)}</span>
                </div>
            </div>
        `).join('');
    }

    renderDocuments(documents) {
        const container = document.getElementById('documents-list');

        if (documents.length === 0) {
            container.innerHTML = '<div class="empty">No documents yet</div>';
            return;
        }

        container.innerHTML = documents.map(doc => `
            <div class="document-card">
                <div class="document-header">
                    <div class="document-title">${this.escapeHtml(doc.title)}</div>
                    <div class="document-badges">
                        ${doc.isPinned ? '<span class="badge badge-pinned">Pinned</span>' : ''}
                        ${doc.isDefault ? '<span class="badge badge-default">Default</span>' : ''}
                    </div>
                </div>
                ${doc.path ? `<div class="document-path">${this.escapeHtml(doc.path)}</div>` : ''}
                ${doc.content ? `<div class="document-preview">${this.escapeHtml(doc.content)}</div>` : ''}
            </div>
        `).join('');
    }

    renderError(containerId, message) {
        const container = document.getElementById(containerId);
        container.innerHTML = `<div class="empty" style="color: #f44336;">${message}</div>`;
    }

    // Utility Methods
    formatStatus(status) {
        const statusMap = {
            'inbox': 'Inbox',
            'todo': 'To Do',
            'inProgress': 'In Progress',
            'done': 'Done'
        };
        return statusMap[status] || status;
    }

    formatDate(dateString) {
        if (!dateString) return '';
        const date = new Date(dateString);
        const now = new Date();
        const diff = now - date;
        const minutes = Math.floor(diff / 60000);
        const hours = Math.floor(diff / 3600000);
        const days = Math.floor(diff / 86400000);

        if (minutes < 1) return 'just now';
        if (minutes < 60) return `${minutes}m ago`;
        if (hours < 24) return `${hours}h ago`;
        if (days < 7) return `${days}d ago`;
        return date.toLocaleDateString();
    }

    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    startAutoRefresh() {
        setInterval(() => {
            this.loadAll();
        }, this.refreshInterval);
    }
}

// Initialize dashboard when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    window.dashboard = new MaestroDashboard();
});
