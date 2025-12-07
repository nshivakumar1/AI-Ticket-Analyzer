import { Link } from 'react-router-dom'
import { Ticket } from '../services/api'

interface TicketCardProps {
  ticket: Ticket
}

export default function TicketCard({ ticket }: TicketCardProps) {
  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'P1':
        return 'bg-red-100 text-red-800'
      case 'P2':
        return 'bg-orange-100 text-orange-800'
      case 'P3':
        return 'bg-yellow-100 text-yellow-800'
      case 'P4':
        return 'bg-green-100 text-green-800'
      default:
        return 'bg-gray-100 text-gray-800'
    }
  }

  const getSentimentColor = (sentiment: string) => {
    switch (sentiment) {
      case 'Angry':
        return 'bg-red-100 text-red-800'
      case 'Positive':
        return 'bg-green-100 text-green-800'
      default:
        return 'bg-gray-100 text-gray-800'
    }
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'New':
        return 'bg-blue-100 text-blue-800'
      case 'In-Progress':
        return 'bg-yellow-100 text-yellow-800'
      case 'Resolved':
        return 'bg-green-100 text-green-800'
      default:
        return 'bg-gray-100 text-gray-800'
    }
  }

  return (
    <Link
      to={`/ticket/${ticket.ticket_id}`}
      className="block bg-white rounded-lg shadow hover:shadow-md transition-shadow p-6"
    >
      <div className="flex items-start justify-between">
        <div className="flex-1">
          <div className="flex items-center gap-2 mb-2">
            <h3 className="text-lg font-semibold text-gray-900">
              {ticket.subject}
            </h3>
            {ticket.is_vip && (
              <span className="px-2 py-1 text-xs font-semibold rounded-full bg-purple-100 text-purple-800">
                VIP
              </span>
            )}
          </div>
          <p className="text-sm text-gray-600 mb-3 line-clamp-2">
            {ticket.body}
          </p>
          <div className="flex flex-wrap gap-2">
            <span
              className={`px-2 py-1 text-xs font-semibold rounded-full ${getPriorityColor(
                ticket.priority
              )}`}
            >
              {ticket.priority}
            </span>
            <span className="px-2 py-1 text-xs font-semibold rounded-full bg-gray-100 text-gray-800">
              {ticket.category}
            </span>
            <span
              className={`px-2 py-1 text-xs font-semibold rounded-full ${getSentimentColor(
                ticket.sentiment
              )}`}
            >
              {ticket.sentiment}
            </span>
            <span
              className={`px-2 py-1 text-xs font-semibold rounded-full ${getStatusColor(
                ticket.status
              )}`}
            >
              {ticket.status}
            </span>
          </div>
        </div>
      </div>
      <div className="mt-4 pt-4 border-t border-gray-200">
        <div className="flex items-center justify-between text-sm text-gray-500">
          <span>{ticket.customer_email}</span>
          <span>{new Date(ticket.created_at).toLocaleDateString()}</span>
        </div>
      </div>
    </Link>
  )
}

