package com.spl2.uniconnect.base;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.junit.jupiter.MockitoExtension;

/**
 * Base class for all Unit Tests
 * Unit tests test ONE component in isolation using mocks
 * 
 * Extend this for: Service tests, Mapper tests, Utility tests
 */
@ExtendWith(MockitoExtension.class)
public abstract class BaseUnitTest {

    @BeforeEach
    public void baseSetUp() {
        // Common setup for all unit tests if needed
    }
}
