import { Module } from '@nestjs/common';
import { AuthModule }                from '../auth/auth.module';
import { UsersModule }               from '../users/users.module';
import { GatewayModule }             from '../gateway/gateway.module';
import { NotificationsModule }       from '../notifications/notifications.module';
import { ServiceRequestsService }    from './service-requests.service';
import { ServiceRequestsController } from './service-requests.controller';

@Module({
  // GatewayModule → ServiceRequestGateway (WS); NotificationsModule → FCM+inbox.
  imports: [AuthModule, UsersModule, GatewayModule, NotificationsModule],
  controllers: [ServiceRequestsController],
  providers:   [ServiceRequestsService],
  exports:     [ServiceRequestsService],
})
export class ServiceRequestsModule {}
