# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # CSRF Protection - protects against Cross-Site Request Forgery attacks
  protect_from_forgery with: :exception

  # Security headers for additional protection
  before_action :set_security_headers

  # Handle CSRF token verification failures gracefully
  rescue_from ActionController::InvalidAuthenticityToken, with: :handle_csrf_error

  private

  def set_security_headers
    # Prevent clickjacking attacks
    response.headers['X-Frame-Options'] = 'DENY'

    # Prevent MIME type sniffing
    response.headers['X-Content-Type-Options'] = 'nosniff'

    # Enable XSS protection
    response.headers['X-XSS-Protection'] = '1; mode=block'

    # Referrer policy for privacy
    response.headers['Referrer-Policy'] = 'strict-origin-when-cross-origin'
  end

  def handle_csrf_error
    Rails.logger.warn "CSRF token verification failed for #{request.remote_ip}"
    redirect_to root_path, alert: 'Security token expired. Please try again.'
  end
end
