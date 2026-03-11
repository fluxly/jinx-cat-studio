/**
 * Types for the `camera` bridge namespace.
 */

/** Result returned after a camera capture attempt. */
export interface CaptureResult {
  status: 'captured' | 'cancelled' | 'failed' | 'unavailable';
  imageBase64?: string;
  error?: string;
}
