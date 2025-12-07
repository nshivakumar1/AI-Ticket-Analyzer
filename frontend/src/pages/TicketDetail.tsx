import { useState, useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { ticketService, Ticket } from '../services/api'

export default function TicketDetail() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const [ticket, setTicket] = useState<Ticket | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [reanalyzing, setReanalyzing] = useState(false)
  const [updating, setUpdating] = useState(false)
  const [status, setStatus] = useState<string>('')

  useEffect(() => {
    if (id) {
      loadTicket()
    }
  }, [id])

  const loadTicket = async () => {
    if (!id) return
    try {
      setLoading(true)
      setError(null)
      const data = await ticketService.get(id)
      setTicket(data)
      setStatus(data.status)
    } catch (err) {
      setError('Failed to load ticket')
      console.error(err)
    } finally {
      setLoading(false)
    }
  }

  const handleReanalyze = async () => {
    if (!id) return
    try {
      setReanalyzing(true)
      const updated = await ticketService.reanalyze(id)
      setTicket(updated)
    } catch (err) {
      setError('Failed to reanalyze ticket')
      console.error(err)
    } finally {
      setReanalyzing(false)
    }
  }

  const handleStatusUpdate = async () => {
    if (!id || !ticket) return
    try {
      setUpdating(true)
      const updated = await ticketService.update(id, { status: status as any })
      setTicket(updated)
    } catch (err) {
      setError('Failed to update ticket')
      console.error(err)
    } finally {
      setUpdating(false)
    }
  }

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

  if (loading) {
    return (
      <div className="px-4 sm:px-6 lg:px-8">
        <div className="text-center py-12">
          <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
          <p className="mt-2 text-gray-600">Loading ticket...</p>
        </div>
      </div>
    )
  }

  if (error || !ticket) {
    return (
      <div className="px-4 sm:px-6 lg:px-8">
        <div className="bg-red-50 border border-red-200 rounded-lg p-4">
          <p className="text-red-800">{error || 'Ticket not found'}</p>
          <button
            onClick={() => navigate('/')}
            className="mt-4 px-4 py-2 bg-primary-600 text-white rounded-md hover:bg-primary-700"
          >
            Back to Dashboard
          </button>
        </div>
      </div>
    )
  }

  return (
    <div className="px-4 sm:px-6 lg:px-8">
      <div className="mb-6">
        <button
          onClick={() => navigate('/')}
          className="text-primary-600 hover:text-primary-700 mb-4"
        >
          ← Back to Dashboard
        </button>
        <h2 className="text-2xl font-bold text-gray-900">Ticket Details</h2>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Content */}
        <div className="lg:col-span-2 space-y-6">
          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-start justify-between mb-4">
              <h3 className="text-xl font-semibold text-gray-900">
                {ticket.subject}
              </h3>
              {ticket.is_vip && (
                <span className="px-3 py-1 text-sm font-semibold rounded-full bg-purple-100 text-purple-800">
                  VIP
                </span>
              )}
            </div>
            <p className="text-gray-700 whitespace-pre-wrap">{ticket.body}</p>
          </div>

          <div className="bg-white rounded-lg shadow p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">
              AI Suggested Reply
            </h3>
            <div className="bg-gray-50 rounded-lg p-4">
              <p className="text-gray-700 whitespace-pre-wrap">
                {ticket.ai_suggested_reply}
              </p>
            </div>
            <button
              onClick={handleReanalyze}
              disabled={reanalyzing}
              className="mt-4 px-4 py-2 bg-primary-600 text-white rounded-md hover:bg-primary-700 disabled:opacity-50"
            >
              {reanalyzing ? 'Reanalyzing...' : 'Reanalyze with AI'}
            </button>
          </div>
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          <div className="bg-white rounded-lg shadow p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">
              Ticket Information
            </h3>
            <dl className="space-y-4">
              <div>
                <dt className="text-sm font-medium text-gray-500">Ticket ID</dt>
                <dd className="mt-1 text-sm text-gray-900 font-mono">
                  {ticket.ticket_id}
                </dd>
              </div>
              <div>
                <dt className="text-sm font-medium text-gray-500">Customer</dt>
                <dd className="mt-1 text-sm text-gray-900">
                  {ticket.customer_name || ticket.customer_email}
                </dd>
                <dd className="text-sm text-gray-500">{ticket.customer_email}</dd>
              </div>
              <div>
                <dt className="text-sm font-medium text-gray-500">Created</dt>
                <dd className="mt-1 text-sm text-gray-900">
                  {new Date(ticket.created_at).toLocaleString()}
                </dd>
              </div>
            </dl>
          </div>

          <div className="bg-white rounded-lg shadow p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">
              Classification
            </h3>
            <div className="space-y-3">
              <div>
                <dt className="text-sm font-medium text-gray-500 mb-1">Priority</dt>
                <dd>
                  <span
                    className={`inline-block px-3 py-1 text-sm font-semibold rounded-full ${getPriorityColor(
                      ticket.priority
                    )}`}
                  >
                    {ticket.priority}
                  </span>
                </dd>
              </div>
              <div>
                <dt className="text-sm font-medium text-gray-500 mb-1">Category</dt>
                <dd>
                  <span className="inline-block px-3 py-1 text-sm font-semibold rounded-full bg-gray-100 text-gray-800">
                    {ticket.category}
                  </span>
                </dd>
              </div>
              <div>
                <dt className="text-sm font-medium text-gray-500 mb-1">Sentiment</dt>
                <dd>
                  <span
                    className={`inline-block px-3 py-1 text-sm font-semibold rounded-full ${getSentimentColor(
                      ticket.sentiment
                    )}`}
                  >
                    {ticket.sentiment}
                  </span>
                </dd>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-lg shadow p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">
              Status
            </h3>
            <div className="space-y-3">
              <select
                value={status}
                onChange={(e) => setStatus(e.target.value)}
                className="w-full rounded-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500"
              >
                <option value="New">New</option>
                <option value="In-Progress">In-Progress</option>
                <option value="Resolved">Resolved</option>
              </select>
              <button
                onClick={handleStatusUpdate}
                disabled={updating || status === ticket.status}
                className="w-full px-4 py-2 bg-primary-600 text-white rounded-md hover:bg-primary-700 disabled:opacity-50"
              >
                {updating ? 'Updating...' : 'Update Status'}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

