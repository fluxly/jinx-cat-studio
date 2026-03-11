/**
 * Types for the `mail` bridge namespace.
 */

/** Parameters for composing a text note email. */
export interface NotePayload {
  category?: string;
  tagPrimary?: string;
  tagSecondary?: string;
  tagTertiary?: string;
  subject?: string;
  body?: string;
}

/** Parameters for composing a photo email. */
export interface PhotoPayload {
  category?: string;
  tagPrimary?: string;
  tagSecondary?: string;
  tagTertiary?: string;
  subject?: string;
  imageBase64?: string;
}

/** Result returned after a mail compose operation. */
export interface MailResult {
  status: 'sent' | 'saved' | 'cancelled' | 'failed' | 'presented';
}
