/**
 * email-view — ensures <email-note-view> component is registered.
 *
 * The email view is rendered inline by app-shell when currentView === 'email'.
 * It contains <email-note-view> which handles the full composition flow.
 *
 * This module exists to mirror the view architecture and can be extended
 * to a full Web Component if additional layout or wrapper logic is needed.
 */
import '../components/email-note-view.js';

export {};
