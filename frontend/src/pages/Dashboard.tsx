import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { ticketService, TicketFilters } from '../services/api'
import TicketCard from '../components/TicketCard'

export default function Dashboard() {
  const [filters, setFilters] = useState<TicketFilters>({
    page: 1,
    page_size: 20,
  })

  const { data, isLoading, error } = useQuery({
    queryKey: ['tickets', filters],
    queryFn: () => ticketService.list(filters),
  })

  const tickets = data?.tickets || []
  const total = data?.total || 0

  const handleFilterChange = (key: keyof TicketFilters, value: any) => {
    setFilters((prev) => ({
      ...prev,
      [key]: value || undefined,
      page: 1, // Reset to first page on filter change
    }))
  }

  return (
    <div className="px-4 sm:px-6 lg:px-8">
      <div className="mb-6">
        <h2 className="text-2xl font-bold text-gray-900 mb-4">Ticket Dashboard</h2>

        {/* Filters */}
        <div className="bg-white p-4 rounded-lg shadow mb-6">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Status
              </label>
              <select
                value={filters.status || ''}
                onChange={(e) => handleFilterChange('status', e.target.value)}
                className="w-full rounded-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500"
              >
                <option value="">All</option>
                <option value="New">New</option>
                <option value="In-Progress">In-Progress</option>
                <option value="Resolved">Resolved</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Priority
              </label>
              <select
                value={filters.priority || ''}
                onChange={(e) => handleFilterChange('priority', e.target.value)}
                className="w-full rounded-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500"
              >
                <option value="">All</option>
                <option value="P1">P1 - Critical</option>
                <option value="P2">P2 - High</option>
                <option value="P3">P3 - Medium</option>
                <option value="P4">P4 - Low</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Category
              </label>
              <select
                value={filters.category || ''}
                onChange={(e) => handleFilterChange('category', e.target.value)}
                className="w-full rounded-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500"
              >
                <option value="">All</option>
                <option value="Billing">Billing</option>
                <option value="Login">Login</option>
                <option value="Performance">Performance</option>
                <option value="Bug">Bug</option>
                <option value="Feature Request">Feature Request</option>
                <option value="Access">Access</option>
                <option value="Other">Other</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Sentiment
              </label>
              <select
                value={filters.sentiment || ''}
                onChange={(e) => handleFilterChange('sentiment', e.target.value)}
                className="w-full rounded-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500"
              >
                <option value="">All</option>
                <option value="Angry">Angry</option>
                <option value="Neutral">Neutral</option>
                <option value="Positive">Positive</option>
              </select>
            </div>
          </div>
        </div>
      </div>

      {/* Loading State */}
      {isLoading && (
        <div className="text-center py-12">
          <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
          <p className="mt-2 text-gray-600">Loading tickets...</p>
        </div>
      )}

      {/* Error State */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-6">
          <p className="text-red-800">
            Failed to load tickets. Please check if the API is running.
          </p>
        </div>
      )}

      {/* Tickets List */}
      {!isLoading && !error && (
        <>
          <div className="mb-4 text-sm text-gray-600">
            Showing {tickets.length} of {total} tickets
          </div>
          {tickets.length === 0 ? (
            <div className="bg-white rounded-lg shadow p-12 text-center">
              <p className="text-gray-500">No tickets found. Create your first ticket!</p>
            </div>
          ) : (
            <div className="grid gap-4">
              {tickets.map((ticket) => (
                <TicketCard key={ticket.ticket_id} ticket={ticket} />
              ))}
            </div>
          )}
        </>
      )}
    </div>
  )
}

