class Membership < ActiveRecord::Base

	include ActionView::Helpers::NumberHelper

	belongs_to :user

	validates_presence_of :valid_from, :duration

	def self.calculate_membership_price(duration, options = {})
		
		autodebit = options[:autodebit] or false
		concession = options[:concession] or false

		# Base price for 1 month
		price = 4000
		
		if autodebit
			case duration
			when 6
				price = price * duration * 0.8
			when 12
				price = price * duration * 0.8
			end
		else
			case duration
			when 6
				price = price * duration
			when 12
				price = price * duration
			end
		end
		if concession
			case duration
			when 6
				price *= 0.5
			when 12
				price *= 0.5
			end
		end
		return price
	end

	def is_current?
		return (expiry_date > DateTime.now)
	end

	def is_recurring?
		return (was_recurring? and (not is_cancelled?))
	end

	def is_cancelled?
		return false
	end

	def expiry_date
		return (cancellation_date or (valid_from + duration.months))
	end

	def was_recurring?
		return (not self.paypal_profile_id.blank?)
	end

	def pretty_price_paid
		return self.price_paid ? "$#{number_with_precision((self.price_paid / 100), :precision => 2)}" : "Free"
	end

	def calculate_refund
		# TODO: Write autodebit renewal after we've implemented it.
		# FIXME: write the logic to calculate refunds properly.
		self.refund = [0,(1-(used_days/total_days))*self.price_paid].max.floor
		logger.warn "Refund of #{self.refund} cents due."
	end

	def used_days
		return [0,(DateTime.now - self.valid_from.to_datetime).to_f].max
	end

	def total_days
		return (self.expiry_date.to_datetime - self.valid_from.to_datetime).to_f
	end

	def expire_membership
		self.calculate_refund
		self.cancellation_date = DateTime.now
	end

end
