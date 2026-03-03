namespace TruckMate.Core.Models
{
    public class Driver
    {
        public int Id { get; set; }

        public string LicenseNumber { get; set; } = string.Empty;
        public string LicenseType { get; set; } = string.Empty;


        public int UserId { get; set; }
        public User User { get; set; } = null!;

        public int YearsOfExperience { get; set; }

        public bool IsAvailable { get; set; }


    }
}
