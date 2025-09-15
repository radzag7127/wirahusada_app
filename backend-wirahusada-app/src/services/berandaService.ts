import { PaymentService } from "./paymentService";
import { AkademikService } from "./akademikService";

export class BerandaService {
  private paymentService: PaymentService;
  private akademikService: AkademikService;

  constructor() {
    this.paymentService = new PaymentService();
    this.akademikService = new AkademikService();
  }

  /**
   * Get aggregated data for Beranda (Homepage)
   * Combines payment summary and transcript summary data
   */
  async getBerandaData(nrm: string) {
    console.log("🏠 BERANDA SERVICE - getBerandaData called:", {
      nrm,
      nrmType: typeof nrm,
      timestamp: new Date().toISOString(),
    });

    try {
      // Fetch payment summary and transcript summary in parallel
      // Use Promise.allSettled to prevent one failure from breaking everything
      const [paymentResult, transcriptResult] = await Promise.allSettled([
        this.paymentService.getPaymentSummary(nrm),
        this.akademikService.getTranscriptSummary(nrm),
      ]);

      const paymentSummary =
        paymentResult.status === "fulfilled" ? paymentResult.value : null;
      const transcriptSummary =
        transcriptResult.status === "fulfilled" ? transcriptResult.value : null;

      // Log any failures for debugging
      if (paymentResult.status === "rejected") {
        console.warn(
          "🏠 BERANDA SERVICE - Payment data failed:",
          paymentResult.reason
        );
      }
      if (transcriptResult.status === "rejected") {
        console.warn(
          "🏠 BERANDA SERVICE - Transcript data failed:",
          transcriptResult.reason
        );
      }

      const berandaData = {
        payment: paymentSummary,
        transcript: transcriptSummary,
        announcements: [
          {
            id: "1",
            title: "Tetap Terinformasi!",
            description:
              'Jangan lewatkan acara Seminar Nasional Kesehatan "Inovasi dalam Penanganan Covid-29" pada tanggal 10 Juli 2025. Daftar sekarang!',
            imageUrl: "https://picsum.photos/seed/seminar/800/600",
            articleUrl: "https://wira-husada-nusantara.ac.id/news/seminar",
            status: "active",
            createdAt: new Date().toISOString(),
          },
          {
            id: "2",
            title: "Pendaftaran Mahasiswa Baru",
            description:
              "Periode pendaftaran mahasiswa baru telah dibuka. Dapatkan informasi lengkap di sini.",
            imageUrl: "https://picsum.photos/seed/pmb/800/600",
            articleUrl: "https://wira-husada-nusantara.ac.id/news/pmb",
            status: "active",
            createdAt: new Date().toISOString(),
          },
        ],
        libraryServices: [
          {
            id: "repository",
            title: "Buku",
            status: "coming_soon",
            href: "/perpustakaan/buku",
          },
          {
            id: "jurnal_whn",
            title: "Jurnal",
            status: "coming_soon",
            href: "/perpustakaan/jurnal",
          },
          {
            id: "e_library",
            title: "Skripsi",
            status: "coming_soon",
            href: "/perpustakaan/skripsi",
          },
          {
            id: "e_resources",
            title: "Semua Koleksi",
            status: "coming_soon",
            href: "/perpustakaan",
          },
        ],
      };

      console.log("🏠 BERANDA SERVICE - Data fetched successfully:", {
        hasPaymentData: !!paymentSummary,
        hasTranscriptData: !!transcriptSummary,
        announcementsCount: berandaData.announcements.length,
        libraryServicesCount: berandaData.libraryServices.length,
      });

      return berandaData;
    } catch (error) {
      console.error("🏠 BERANDA SERVICE - Error fetching beranda data:", error);
      throw error;
    }
  }

  /**
   * Get announcements for hero carousel
   * Returns hard-coded announcement data for now
   */
  async getAnnouncements() {
    console.log("🏠 BERANDA SERVICE - getAnnouncements called:", {
      timestamp: new Date().toISOString(),
    });

    try {
      // TODO: Replace with database query when ready
      const announcements = [
        {
          id: "1",
          title: "Gedung Baru WHN",
          description:
            "Peresmian gedung baru untuk fasilitas belajar mengajar yang modern dan nyaman.",
          imageUrl: "https://picsum.photos/seed/1/800/600",
          articleUrl: "https://wira-husada-nusantara.ac.id/news/1",
          status: "active",
          createdAt: new Date().toISOString(),
        },
        {
          id: "2",
          title: "Seminar Kesehatan Nasional",
          description:
            'Jangan lewatkan seminar nasional "Inovasi dalam Penanganan Covid-29" tanggal 10 Juli 2025.',
          imageUrl: "https://picsum.photos/seed/2/800/600",
          articleUrl: "https://wira-husada-nusantara.ac.id/news/2",
          status: "active",
          createdAt: new Date().toISOString(),
        },
        {
          id: "3",
          title: "Pendaftaran Mahasiswa Baru",
          description:
            "Periode pendaftaran mahasiswa baru telah dibuka! Dapatkan informasi lengkap di website resmi.",
          imageUrl: "https://picsum.photos/seed/3/800/600",
          articleUrl: "https://wira-husada-nusantara.ac.id/news/3",
          status: "active",
          createdAt: new Date().toISOString(),
        },
      ];

      console.log("🏠 BERANDA SERVICE - Announcements fetched successfully:", {
        count: announcements.length,
      });

      return announcements;
    } catch (error) {
      console.error(
        "🏠 BERANDA SERVICE - Error fetching announcements:",
        error
      );
      throw error;
    }
  }
}
