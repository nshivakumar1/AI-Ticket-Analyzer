import axios from 'axios'

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000'

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
})

export interface Ticket {
  ticket_id: string
  created_at: string
  customer_email: string
  customer_name?: string
  subject: string
  body: string
  priority: 'P1' | 'P2' | 'P3' | 'P4'
  category: string
  sentiment: 'Angry' | 'Neutral' | 'Positive'
  status: 'New' | 'In-Progress' | 'Resolved'
  ai_suggested_reply: string
  is_vip: boolean
}

export interface TicketCreate {
  customer_email: string
  subject: string
  body: string
  customer_name?: string
  is_vip: boolean
}

export interface TicketUpdate {
  subject?: string
  body?: string
  status?: 'New' | 'In-Progress' | 'Resolved'
}

export interface TicketListResponse {
  tickets: Ticket[]
  total: number
  page: number
  page_size: number
}

export interface TicketFilters {
  status?: 'New' | 'In-Progress' | 'Resolved'
  priority?: 'P1' | 'P2' | 'P3' | 'P4'
  category?: string
  sentiment?: 'Angry' | 'Neutral' | 'Positive'
  page?: number
  page_size?: number
}

export const ticketService = {
  create: async (ticket: TicketCreate): Promise<Ticket> => {
    const response = await api.post<Ticket>('/tickets', ticket)
    return response.data
  },

  list: async (filters?: TicketFilters): Promise<TicketListResponse> => {
    const params = new URLSearchParams()
    if (filters?.status) params.append('status', filters.status)
    if (filters?.priority) params.append('priority', filters.priority)
    if (filters?.category) params.append('category', filters.category)
    if (filters?.sentiment) params.append('sentiment', filters.sentiment)
    if (filters?.page) params.append('page', filters.page.toString())
    if (filters?.page_size) params.append('page_size', filters.page_size.toString())

    const response = await api.get<TicketListResponse>(`/tickets?${params.toString()}`)
    return response.data
  },

  get: async (id: string): Promise<Ticket> => {
    const response = await api.get<Ticket>(`/tickets/${id}`)
    return response.data
  },

  update: async (id: string, update: TicketUpdate): Promise<Ticket> => {
    const response = await api.patch<Ticket>(`/tickets/${id}`, update)
    return response.data
  },

  reanalyze: async (id: string): Promise<Ticket> => {
    const response = await api.post<Ticket>(`/tickets/${id}/reanalyze`)
    return response.data
  },
}

