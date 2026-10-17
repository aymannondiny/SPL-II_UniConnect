package com.uniconnect.chat.service;
import java.util.Set;
public record ChatChanged(Set<Long> userIds) {}
