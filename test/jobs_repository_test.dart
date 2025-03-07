import 'package:test/test.dart';
import 'package:supabase/supabase.dart';
import '../output/repositories/jobs_repository.dart';
import '../output/models/jobs.dart';

void main() {
  late SupabaseClient client;
  late JobsRepository jobsRepository;

  setUp(() {
    // Initialize Supabase client for local development
    client = SupabaseClient(
      'http://localhost:54321', // Local Supabase URL
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0', // Local anon key
    );
    jobsRepository = JobsRepository(client);
  });

  group('JobsRepository Tests', () {
    test('Get jobs by professional ID', () async {
      const professionalId = '08d82f7c-b99c-4908-9921-a7406a941a14';

      final jobs = await jobsRepository.getByProfessionalId(professionalId);

      // Print results
      print('Found ${jobs.length} jobs for professional $professionalId:');
      for (final job in jobs) {
        print('Job ID: ${job.jobId}');
        print('Service ID: ${job.serviceId}');
        print('Current Stage: ${job.currentStage}');
        print('Created At: ${job.createdAt}');
        print('---');
      }

      // Basic assertions
      expect(jobs, isA<List<Jobs>>());
      for (final job in jobs) {
        expect(job.professionalId, equals(professionalId));
      }
    });
  });
}
