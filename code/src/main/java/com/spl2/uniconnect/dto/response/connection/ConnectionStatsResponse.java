package com.spl2.uniconnect.dto.response.connection;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ConnectionStatsResponse {

    private long totalConnections;
    private long pendingRequestsReceived;
    private long pendingRequestsSent;
}