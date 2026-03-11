/**
 * camera-compose-view — ensures <camera-view> component is registered.
 *
 * The camera compose view is rendered inline by app-shell when currentView === 'camera'.
 * It contains <camera-view> which handles capture and photo-mail composition.
 *
 * This module exists to mirror the view architecture and can be extended
 * to a full Web Component if additional layout or wrapper logic is needed.
 */
import '../components/camera-view.js';

export {};
