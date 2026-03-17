import * as admin from "firebase-admin";
import * as fft from "firebase-functions-test";
import { onCreateRecurringAppointment } from "../appointments/onCreateRecurringAppointment";

const testEnv = fft();
admin.initializeApp();

describe("onCreateRecurringAppointment Eager Generation Time Preservation", () => {
  let wrapped: any;

  beforeAll(() => {
    // Wrap the cloud function
    wrapped = testEnv.wrap(onCreateRecurringAppointment);
  });

  afterAll(() => {
    testEnv.cleanup();
  });

  it("should preserve the time of baseDate when generating eager appointments", async () => {
    // 1. Setup Original Date with specific time
    const baseDate = new Date();
    // Set time to 15:30:45.500
    baseDate.setHours(15, 30, 45, 500);

    // 2. Setup mock data for the recurring appointment
    const snap = testEnv.firestore.makeDocumentSnapshot(
      {
        active: true,
        concept: "Terapia",
        defaultAmount: 15000,
        frequency: "weekly",
        baseDate: admin.firestore.Timestamp.fromDate(baseDate),
        endDate: null
      },
      "providers/provider_123/patients/patient_456/recurring_appointments/recurring_789"
    );

    // We need to mock admin.firestore() globally or intercept the set
    // A simpler way for this environment without extensive mocking is just
    // tracking the calls to set.

    const mockSet = jest.fn();
    const mockUpdate = jest.fn();

    // Mock the parent references to avoid actual DB calls
    snap.ref.update = mockUpdate;
    Object.defineProperty(snap.ref, "parent", {
      get: () => ({
        parent: {
          collection: (col: string) => ({
            doc: () => ({
              set: mockSet,
            })
          })
        }
      })
    });

    // Mock the provider lookup for holidays/vacations
    const mockProviderGet = jest.fn().mockResolvedValue({
      data: () => ({ nonWorkingDays: [], vacations: [] })
    });

    const originalCollection = admin.firestore().collection;
    jest.spyOn(admin.firestore(), "collection").mockImplementation((path) => {
      if (path === "providers") {
        return {
          doc: () => ({
            get: mockProviderGet
          })
        } as any;
      }
      return originalCollection(path);
    });

    // 3. Execute cloud function
    await wrapped(snap, {
      params: {
        providerId: "provider_123",
        patientId: "patient_456",
        recurringId: "recurring_789"
      }
    });

    // Restore original
    jest.restoreAllMocks();

    // 4. Assertions
    // since baseDate is today, the eager generation should create 1 appointment
    expect(mockSet).toHaveBeenCalled();
    
    // Check the arguments passed to set()
    const setArgs = mockSet.mock.calls[0][0];
    const savedDate: Date = setArgs.date.toDate();

    expect(savedDate.getHours()).toBe(15);
    expect(savedDate.getMinutes()).toBe(30);
    expect(savedDate.getSeconds()).toBe(45);
    expect(savedDate.getMilliseconds()).toBe(500);
  });
});
