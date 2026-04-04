import { apiClient } from './api';
import { API_CONFIG } from '@/constants';

export interface PaymentGateway {
  id: string;
  name: string;
  provider: string;
  isActive: boolean;
}

export interface TopUpRequest {
  amount: number;
  gateway: string;
}

export interface TopUpResponse {
  success: boolean;
  invoice?: {
    id: string;
    invoiceNumber: string;
    paymentLink: string;
  };
  error?: string;
}

export class TopUpService {
  /**
   * Get available payment gateways
   */
  static async getPaymentGateways(): Promise<PaymentGateway[]> {
    try {
      const response = await apiClient.get<{ success: boolean; gateways: PaymentGateway[] }>(
        API_CONFIG.ENDPOINTS.PAYMENT_GATEWAYS
      );
      
      if (response.success && response.gateways) {
        return response.gateways;
      }
      
      return [];
    } catch (error) {
      console.error('Get payment gateways error:', error);
      return [];
    }
  }

  /**
   * Create top-up payment
   */
  static async createTopUp(data: TopUpRequest): Promise<TopUpResponse> {
    try {
      const response = await apiClient.post<TopUpResponse>(
        API_CONFIG.ENDPOINTS.TOPUP_DIRECT,
        data
      );
      
      return response;
    } catch (error: any) {
      console.error('Create top-up error:', error);
      return {
        success: false,
        error: error.response?.data?.error || 'Gagal membuat top-up',
      };
    }
  }
}
