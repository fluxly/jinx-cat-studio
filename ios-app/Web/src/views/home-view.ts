/**
 * home-view — re-exports the home-view markup composition.
 *
 * The home view is rendered inline by app-shell when currentView === 'home'.
 * It contains <main-menu-card> which handles navigation dispatching.
 *
 * This module exists to mirror the view architecture and can be extended
 * to a full Web Component if additional home-view logic is needed.
 */
import '../components/main-menu-card.js';

export {};
